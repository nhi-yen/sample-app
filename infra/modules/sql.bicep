@description('Logical SQL Server name.')
param serverName string

@description('Database name.')
param databaseName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Entra principal ID (user, group, or SP) that becomes the SQL AD admin.')
param adminPrincipalId string

@description('Display name / UPN of the SQL AD admin (metadata only).')
param adminPrincipalName string

@description('Type of Entra principal.')
@allowed([ 'User', 'Group', 'ServicePrincipal' ])
param adminPrincipalType string

@description('Serverless auto-pause delay in minutes. 60 = aggressive savings for dev.')
param autoPauseDelayMinutes int = 60

@description('Minimum vCores when active. Serverless allows 0.5.')
param minCapacity string = '0.5'

@description('Maximum vCores.')
param maxVCores int = 1

@description('Max database size in GB.')
param maxSizeGB int = 32

resource server 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: serverName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Entra-only authentication. No SQL auth, no passwords.
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: adminPrincipalName
      sid: adminPrincipalId
      principalType: adminPrincipalType
      tenantId: tenant().tenantId
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
    version: '12.0'
  }
}

// Allow Azure services (App Service outbound IPs) to reach this server.
resource allowAzure 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: server
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: databaseName
  parent: server
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5_${maxVCores}'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: maxVCores
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: maxSizeGB * 1024 * 1024 * 1024
    autoPauseDelay: autoPauseDelayMinutes
    minCapacity: json(minCapacity)
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    // Enable the "free" serverless offer (100K vCore-sec/mo).
    // Comment out if your subscription has already consumed the offer on another DB.
    useFreeLimit: true
    freeLimitExhaustionBehavior: 'AutoPause'
  }
  dependsOn: [
    allowAzure
  ]
}

output serverName string = server.name
output serverFqdn string = server.properties.fullyQualifiedDomainName
output databaseName string = database.name
output databaseId string = database.id
