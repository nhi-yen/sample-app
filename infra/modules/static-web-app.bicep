@description('Static Web App name.')
param name string

@description('Azure region. SWA Free is only available in select regions (eastus2, centralus, westus2, westeurope, eastasia).')
param location string

@description('Resource tags.')
param tags object

@description('SKU. "Free" has no linked-backend support; "Standard" does.')
@allowed([ 'Free', 'Standard' ])
param skuName string = 'Free'

resource swa 'Microsoft.Web/staticSites@2024-04-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
  }
  properties: {
    // Source control wiring is handled by the CD workflow via the deployment token,
    // so we create the SWA "unlinked" here.
    provider: 'None'
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

output name string = swa.name
output defaultHostName string = swa.properties.defaultHostname
output id string = swa.id
