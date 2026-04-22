@description('Application Insights component name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Linked Log Analytics workspace resource ID.')
param workspaceId string

resource component 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output name string = component.name
output connectionString string = component.properties.ConnectionString
