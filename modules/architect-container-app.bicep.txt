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

@description('Key Vault secret URI for the architect GitHub token')
param githubTokenSecretUri string

// ---------------------------------------------------------------------
// User-assigned managed identity for ACR pull
//
// Created and granted AcrPull BEFORE the Container App references it.
// A system-assigned identity here creates a circular dependency: the
// Container App needs the role assignment to pull its first image, but
// a role assignment scoped to the Container App's own
// identity.principalId only exists once the Container App resource is
// created — by which point the platform has already attempted (and
// failed) the image pull. This produces repeated "ACR token exchange
// endpoint returned error status: 401" errors and the revision never
// provisions (latestRevisionName stays null indefinitely, eventually
// failing the deployment as "Operation expired").
//
// Using a user-assigned identity, created and role-assigned as
// independent resources before the Container App, with an explicit
// dependsOn forcing the role assignment to complete first, eliminates
// the race entirely.
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
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
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
// Dual identity: system-assigned for fetching the GitHub token secret
// from Key Vault (that role check already passes cleanly), and the
// user-assigned identity above specifically for the ACR registry pull.
// The explicit dependsOn on acrPullRole is the actual fix — it forces
// the role assignment to exist before this resource is created, so the
// platform's first image-pull attempt finds the permission already in
// place instead of racing against it.
// ---------------------------------------------------------------------
resource architectApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'architect'
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
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
          identity: 'system'
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
  ]
}

output containerAppName string = architectApp.name
