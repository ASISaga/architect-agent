// Architect Container App — Claude Code with Remote Control
// Managed by architect-agent/deploy-architect.yml
// Outbound only. No ingress. Scale to zero when idle.
// Dynamic files served from Azure Files share (/root mount).
// Auth: Claude Code authenticates via Google/Anthropic account OAuth —
//       no API key required. Credentials persist to Azure Files share.

@description('Azure region')
param location string

@description('Container Apps Environment name')
param environmentName string

@description('ACR login server')
param acrLoginServer string

@description('ACR name (without .azurecr.io)')
param acrName string

@description('Storage account name for architect-home file share')
param storageAccountName string

@description('Key Vault name (for granting the architect identity access)')
param keyVaultName string

@description('Key Vault secret URI for the architect GitHub token')
param githubTokenSecretUri string

// ---------------------------------------------------------------------
// User-assigned managed identity
//
// Used for BOTH the ACR pull and the Key Vault secret fetch. A single
// identity, created and role-assigned to both resources as independent
// steps BEFORE the Container App exists, with explicit dependsOn
// forcing both role assignments to complete first.
//
// Why not system-assigned: a system-assigned identity does not exist
// until the Container App resource itself is created — and the
// platform attempts its first image pull and secret fetch immediately
// on creation, before any role assignment scoped to that identity
// could possibly have been granted yet (a role assignment needs the
// principalId, which only exists after creation). This produces
// "401 ACR token exchange" and "403 Forbidden... Assignment: (not
// found)" errors that do not self-resolve, because the role is granted
// too late for the first revision's startup attempt, and nothing
// retries the permission check afterward — the revision just stays
// Degraded/Unhealthy indefinitely.
//
// A pre-created, pre-authorized user-assigned identity has no such
// ordering problem: both role assignments exist and have propagated
// before the Container App — and therefore its first revision — is
// ever created.
// ---------------------------------------------------------------------
resource architectIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-architect'
  location: location
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, architectIdentity.id, 'AcrPull')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    )
    principalId: architectIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, architectIdentity.id, 'KeyVaultSecretsUser')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    )
    principalId: architectIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------
// Azure Files share — persists /root across scale-to-zero cycles
// Holds: entrypoint.sh, repos.txt, versions.env, CLAUDE.md,
//        ARCHITECT-CONTEXT.md, claude-settings.json, ~/ASISaga/,
//        ~/.claude/ (Claude Code auth credentials)
// ---------------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource architectHomeShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccountName}/default/architect-home'
  properties: {
    shareQuota: 32
    enabledProtocols: 'SMB'
  }
}

resource caEnv 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
}

resource caStorage 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: caEnv
  name: 'architect-home'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: 'architect-home'
      accessMode: 'ReadWrite'
    }
  }
  dependsOn: [architectHomeShare]
}

// ---------------------------------------------------------------------
// Container App
//
// Single user-assigned identity used for both the ACR registry pull
// and the Key Vault secret fetch — see comment above the identity
// resource. The explicit dependsOn on both role assignments is the
// fix: it forces both roles to exist and have propagated before this
// resource is created, so the platform's first revision finds the
// permissions already in place instead of racing against them.
// ---------------------------------------------------------------------
resource architectApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'architect'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${architectIdentity.id}': {}
    }
  }
  properties: {
    environmentId: caEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: null
      registries: [
        {
          server: acrLoginServer
          identity: architectIdentity.id
        }
      ]
      secrets: [
        {
          name: 'architect-github-token'
          keyVaultUrl: githubTokenSecretUri
          identity: architectIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'architect'
          image: '${acrLoginServer}/aos/architect:latest'
          resources: {
            cpu: json('1.0')
            memory: '2Gi'
          }
          env: [
            { name: 'ARCHITECT_GITHUB_TOKEN', secretRef: 'architect-github-token' }
            { name: 'MIND_MCP_URL', value: 'https://mind.asisaga.com/mcp' }
            { name: 'MIND_MCP_CONNECTION_ID', value: 'mind-mcp-connection' }
          ]
          volumeMounts: [
            {
              volumeName: 'architect-home'
              mountPath: '/root'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
      volumes: [
        {
          name: 'architect-home'
          storageType: 'AzureFile'
          storageName: 'architect-home'
        }
      ]
    }
  }
  dependsOn: [
    caStorage
    acrPullRole
    kvSecretsUserRole
  ]
}

output containerAppName string = architectApp.name
