targetScope = 'subscription'

@description('Environment name (dev, prod).')
@allowed([ 'dev', 'prod' ])
param environmentName string

@description('Short workload name used in resource naming.')
@minLength(2)
@maxLength(10)
param workloadName string = 'notes'

@description('Primary Azure region for all resources.')
param location string = 'eastus2'

@description('Object ID of the Entra principal (user or group) that will be the SQL Entra admin. Required; can be your user object ID.')
param sqlAdminPrincipalId string

@description('Display name of the SQL Entra admin principal (for audit).')
param sqlAdminPrincipalName string

@description('Type of the SQL Entra admin principal.')
@allowed([ 'User', 'Group', 'ServicePrincipal' ])
param sqlAdminPrincipalType string = 'User'

@description('Additional Entra principal IDs (e.g., the GitHub OIDC app reg) granted Key Vault Secrets Officer + SQL admin during CD.')
param deployerPrincipalIds array = []

var tags = {
  environment: environmentName
  workload: workloadName
  'managed-by': 'bicep'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${workloadName}-${environmentName}'
  location: location
  tags: tags
}

module workload 'modules/workload.bicep' = {
  name: 'workload-${environmentName}'
  scope: rg
  params: {
    location: location
    environmentName: environmentName
    workloadName: workloadName
    tags: tags
    sqlAdminPrincipalId: sqlAdminPrincipalId
    sqlAdminPrincipalName: sqlAdminPrincipalName
    sqlAdminPrincipalType: sqlAdminPrincipalType
    deployerPrincipalIds: deployerPrincipalIds
  }
}

output resourceGroupName string = rg.name
output appServiceName string = workload.outputs.appServiceName
output appServiceDefaultHostName string = workload.outputs.appServiceDefaultHostName
output staticWebAppName string = workload.outputs.staticWebAppName
output staticWebAppDefaultHostName string = workload.outputs.staticWebAppDefaultHostName
output keyVaultName string = workload.outputs.keyVaultName
output sqlServerName string = workload.outputs.sqlServerName
output sqlDatabaseName string = workload.outputs.sqlDatabaseName
output applicationInsightsConnectionString string = workload.outputs.applicationInsightsConnectionString
