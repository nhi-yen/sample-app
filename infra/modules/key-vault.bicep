@description('Key Vault name (globally unique, 3-24 chars).')
@minLength(3)
@maxLength(24)
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Principal IDs granted "Key Vault Secrets Officer" (e.g., GitHub OIDC SPs).')
param secretsOfficerPrincipalIds array = []

@description('Enable purge protection. Leave false in dev for easy teardown.')
param enablePurgeProtection bool = false

resource vault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: enablePurgeProtection ? true : null
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

// Key Vault Secrets Officer: can CRUD secrets (used by CD to rotate JWT key).
var secretsOfficerRoleId = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

resource secretsOfficerAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in secretsOfficerPrincipalIds: {
  name: guid(vault.id, principalId, secretsOfficerRoleId)
  scope: vault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretsOfficerRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

output name string = vault.name
output id string = vault.id
output uri string = vault.properties.vaultUri
