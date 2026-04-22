using 'main.bicep'

param environmentName = 'prod'
param workloadName = 'notes'
param location = 'eastus2'

param sqlAdminPrincipalId = readEnvironmentVariable('SQL_ADMIN_OBJECT_ID', '')
param sqlAdminPrincipalName = readEnvironmentVariable('SQL_ADMIN_PRINCIPAL_NAME', '')
param sqlAdminPrincipalType = 'Group'

param deployerPrincipalIds = empty(readEnvironmentVariable('AZURE_DEPLOYER_OBJECT_ID', '')) ? [] : [
  readEnvironmentVariable('AZURE_DEPLOYER_OBJECT_ID', '')
]
