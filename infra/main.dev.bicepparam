using 'main.bicep'

param environmentName = 'dev'
param workloadName = 'notes'
param location = 'eastus2'

// Entra principal that becomes the SQL AD admin.
// Override via CLI: --parameters sqlAdminPrincipalId=$(az ad signed-in-user show --query id -o tsv) sqlAdminPrincipalName=$(az ad signed-in-user show --query userPrincipalName -o tsv)
param sqlAdminPrincipalId = readEnvironmentVariable('SQL_ADMIN_OBJECT_ID', '')
param sqlAdminPrincipalName = readEnvironmentVariable('SQL_ADMIN_PRINCIPAL_NAME', '')
param sqlAdminPrincipalType = 'User'

// The GitHub OIDC service principal object IDs that need to run deployment scripts / rotate secrets.
// Populated by the CD workflow from vars.AZURE_DEPLOYER_OBJECT_ID.
param deployerPrincipalIds = empty(readEnvironmentVariable('AZURE_DEPLOYER_OBJECT_ID', '')) ? [] : [
  readEnvironmentVariable('AZURE_DEPLOYER_OBJECT_ID', '')
]
