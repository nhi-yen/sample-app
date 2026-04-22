@description('App Service Plan name.')
param planName string

@description('App Service (Web App) name.')
param appName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('App Service Plan SKU. F1 = Free, B1 = Basic.')
@allowed([ 'F1', 'B1' ])
param skuName string = 'F1'

@description('.NET runtime version on Linux (e.g., DOTNETCORE|10.0).')
param linuxFxVersion string = 'DOTNETCORE|10.0'

@description('Key Vault name used for JWT signing key reference.')
param keyVaultName string

@description('SQL logical server FQDN.')
param sqlServerFqdn string

@description('SQL database name.')
param sqlDatabaseName string

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('Allowed CORS origin (e.g., https://<swa>.azurestaticapps.net).')
param allowedCorsOrigin string

var skuTier = skuName == 'F1' ? 'Free' : 'Basic'
// F1 does not support Always On.
var alwaysOn = skuName != 'F1'

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    reserved: true // Linux
  }
}

resource site 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/health'
      cors: {
        allowedOrigins: [
          allowedCorsOrigin
        ]
        supportCredentials: true
      }
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'ASPNETCORE_FORWARDEDHEADERS_ENABLED'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'Database__Provider'
          value: 'SqlServer'
        }
        {
          name: 'ConnectionStrings__SqlServer'
          value: 'Server=tcp:${sqlServerFqdn},1433;Database=${sqlDatabaseName};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;'
        }
        {
          name: 'Jwt__SigningKey'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=jwt-signing-key)'
        }
        {
          name: 'Cors__AllowedOrigins__0'
          value: allowedCorsOrigin
        }
        {
          name: 'RUN_MIGRATIONS_ON_START'
          value: 'true'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
      ]
    }
  }
}

// Grant the site's managed identity "Key Vault Secrets User" on the vault.
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

var secretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kvRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, site.id, secretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretsUserRoleId)
    principalId: site.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output name string = site.name
output defaultHostName string = site.properties.defaultHostName
output principalId string = site.identity.principalId
output planId string = plan.id
