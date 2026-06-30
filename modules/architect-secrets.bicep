// Architect secrets — Key Vault entries
// Managed by architect-agent/deploy-architect.yml
// Rotating a secret: update GitHub org secret, re-run deploy-architect.yml
// No image rebuild required.

@description('Key Vault name (existing, from aos-infra)')
param keyVaultName string

@secure()
@description('GitHub PAT for architect git operations (repo, workflow, read:org scopes)')
param architectGithubToken string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource githubSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'architect-github-token'
  properties: {
    value: architectGithubToken
  }
}

output githubTokenSecretUri string = githubSecret.properties.secretUri
