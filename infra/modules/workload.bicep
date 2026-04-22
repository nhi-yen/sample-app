targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Environment name.')
param environmentName string

@description('Short workload name.')
param workloadName string

@description('Resource tags.')
param tags object

@description('Entra principal ID for SQL admin.')
param sqlAdminPrincipalId string

@description('Entra principal display name for SQL admin.')
param sqlAdminPrincipalName string

@description('Entra principal type for SQL admin.')
param sqlAdminPrincipalType string

@description('Additional deployer principal IDs (OIDC SPs) to grant data-plane roles to.')
param deployerPrincipalIds array

var abbrs = loadJsonContent('../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))

// Compose names in one place.
var names = {
  logAnalytics: '${abbrs.logAnalyticsWorkspace}${workloadName}-${environmentName}'
  appInsights: '${abbrs.applicationInsights}${workloadName}-${environmentName}'
  keyVault: '${abbrs.keyVault}${workloadName}-${environmentName}-${substring(resourceToken, 0, 6)}'
  sqlServer: '${abbrs.sqlServer}${workloadName}-${environmentName}-${substring(resourceToken, 0, 6)}'
  sqlDatabase: '${abbrs.sqlDatabase}${workloadName}-${environmentName}'
  appServicePlan: '${abbrs.appServicePlan}${workloadName}-${environmentName}'
  appService: '${abbrs.appService}${workloadName}-${environmentName}-${substring(resourceToken, 0, 6)}'
  staticWebApp: '${abbrs.staticWebApp}${workloadName}-${environmentName}-${substring(resourceToken, 0, 6)}'
}

module logs 'log-analytics.bicep' = {
  name: 'log-analytics'
  params: {
    name: names.logAnalytics
    location: location
    tags: tags
  }
}

module appi 'app-insights.bicep' = {
  name: 'app-insights'
  params: {
    name: names.appInsights
    location: location
    tags: tags
    workspaceId: logs.outputs.workspaceId
  }
}

module kv 'key-vault.bicep' = {
  name: 'key-vault'
  params: {
    name: names.keyVault
    location: location
    tags: tags
    // Deployer SPs get Secrets Officer so CD can rotate the JWT signing key.
    secretsOfficerPrincipalIds: deployerPrincipalIds
  }
}

module sql 'sql.bicep' = {
  name: 'sql'
  params: {
    serverName: names.sqlServer
    databaseName: names.sqlDatabase
    location: location
    tags: tags
    adminPrincipalId: sqlAdminPrincipalId
    adminPrincipalName: sqlAdminPrincipalName
    adminPrincipalType: sqlAdminPrincipalType
  }
}

module app 'app-service.bicep' = {
  name: 'app-service'
  params: {
    planName: names.appServicePlan
    appName: names.appService
    location: location
    tags: tags
    keyVaultName: kv.outputs.name
    sqlServerFqdn: sql.outputs.serverFqdn
    sqlDatabaseName: sql.outputs.databaseName
    appInsightsConnectionString: appi.outputs.connectionString
    allowedCorsOrigin: 'https://${swa.outputs.defaultHostName}'
  }
}

module swa 'static-web-app.bicep' = {
  name: 'static-web-app'
  params: {
    name: names.staticWebApp
    // SWA Free is only available in a limited set of regions; force one that always works.
    location: 'eastus2'
    tags: tags
  }
}

output appServiceName string = app.outputs.name
output appServiceDefaultHostName string = app.outputs.defaultHostName
output appServicePrincipalId string = app.outputs.principalId
output staticWebAppName string = swa.outputs.name
output staticWebAppDefaultHostName string = swa.outputs.defaultHostName
output keyVaultName string = kv.outputs.name
output sqlServerName string = sql.outputs.serverName
output sqlServerFqdn string = sql.outputs.serverFqdn
output sqlDatabaseName string = sql.outputs.databaseName
output applicationInsightsConnectionString string = appi.outputs.connectionString
