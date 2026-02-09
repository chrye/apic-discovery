// ------------------
//    MCP Containers Demo — Deploy MCP servers as containers in Azure Container Apps
//    with APIM as the MCP gateway proxy
// ------------------

// ------------------
//    PARAMETERS
// ------------------

@description('APIM SKU')
param apimSku string = 'Basicv2'

@description('APIM name (must be globally unique)')
param apimName string

@description('APIM subscriptions config')
param apimSubscriptionsConfig array = []

@description('API Center location')
param apicLocation string = resourceGroup().location

@description('API Center name prefix')
param apicServiceNamePrefix string = 'apic'

@description('Container images — set to the ACR image tags after building')
param weatherImage string = 'weather-mcp:latest'
param catalogImage string = 'catalog-mcp:latest'
param orderImage string = 'order-mcp:latest'

// ------------------
//    VARIABLES
// ------------------
var resourceSuffix = uniqueString(subscription().id, resourceGroup().id)

// ------------------
//    RESOURCES
// ------------------

// 1. Log Analytics Workspace
module lawModule '../../modules/operational-insights/v1/workspaces.bicep' = {
  name: 'lawModule'
}

// 2. Application Insights
module appInsightsModule '../../modules/monitor/v1/appinsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    lawId: lawModule.outputs.id
    customMetricsOptedInType: 'WithDimensions'
  }
}

// 3. API Management
module apimModule '../../modules/apim/v2/apim.bicep' = {
  name: 'apimModule'
  params: {
    apimSku: apimSku
    apimName: apimName
    apimSubscriptionsConfig: apimSubscriptionsConfig
    lawId: lawModule.outputs.id
    appInsightsId: appInsightsModule.outputs.id
    appInsightsInstrumentationKey: appInsightsModule.outputs.instrumentationKey
  }
}

// 4. API Center
module apicModule '../../modules/apic/v1/apic.bicep' = {
  name: 'apicModule'
  params: {
    apicServiceName: '${apicServiceNamePrefix}-${resourceSuffix}'
    location: apicLocation
  }
}

// 5. Container Apps Environment + ACR
module acaEnvModule '../../modules/container-apps/v1/environment.bicep' = {
  name: 'acaEnvModule'
  params: {
    lawId: lawModule.outputs.id
  }
}

// 6. Weather MCP Container App
module weatherAppModule '../../modules/container-apps/v1/container-app.bicep' = {
  name: 'weatherAppModule'
  params: {
    containerAppName: 'weather-mcp'
    acaEnvId: acaEnvModule.outputs.acaEnvId
    acrLoginServer: acaEnvModule.outputs.acrLoginServer
    containerImage: weatherImage
    acrUsername: acrUsername
    acrPassword: acrPassword
  }
}

// 7. Product Catalog MCP Container App
module catalogAppModule '../../modules/container-apps/v1/container-app.bicep' = {
  name: 'catalogAppModule'
  params: {
    containerAppName: 'catalog-mcp'
    acaEnvId: acaEnvModule.outputs.acaEnvId
    acrLoginServer: acaEnvModule.outputs.acrLoginServer
    containerImage: catalogImage
    acrUsername: acrUsername
    acrPassword: acrPassword
  }
}

// 8. Place Order MCP Container App
module orderAppModule '../../modules/container-apps/v1/container-app.bicep' = {
  name: 'orderAppModule'
  params: {
    containerAppName: 'order-mcp'
    acaEnvId: acaEnvModule.outputs.acaEnvId
    acrLoginServer: acaEnvModule.outputs.acrLoginServer
    containerImage: orderImage
    acrUsername: acrUsername
    acrPassword: acrPassword
  }
}

// 9. Register Weather MCP in APIM as streamable proxy
module weatherMcpProxy '../../modules/apim-streamable-mcp/api.bicep' = {
  name: 'weatherMcpProxy'
  params: {
    apimServiceName: apimModule.outputs.name
    MCPServiceURL: '${weatherAppModule.outputs.url}/weather'
    MCPPath: 'weather-mcp'
  }
}

// 10. Register Product Catalog MCP in APIM as streamable proxy
module catalogMcpProxy '../../modules/apim-streamable-mcp/api.bicep' = {
  name: 'catalogMcpProxy'
  params: {
    apimServiceName: apimModule.outputs.name
    MCPServiceURL: '${catalogAppModule.outputs.url}/catalog'
    MCPPath: 'catalog-mcp'
  }
}

// 11. Register Place Order MCP in APIM as streamable proxy
module orderMcpProxy '../../modules/apim-streamable-mcp/api.bicep' = {
  name: 'orderMcpProxy'
  params: {
    apimServiceName: apimModule.outputs.name
    MCPServiceURL: '${orderAppModule.outputs.url}/order'
    MCPPath: 'order-mcp'
  }
}

// ------------------
//    ACR credentials (resolved from the deployed ACR)
// ------------------
// NOTE: These are computed from the ACR module outputs — requires admin user enabled
var acrUsername = acr.listCredentials().username
var acrPassword = acr.listCredentials().passwords[0].value

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acaEnvModule.outputs.acrName
}

// ------------------
//    OUTPUTS
// ------------------
output apimServiceName string = apimModule.outputs.name
output apimGatewayUrl string = apimModule.outputs.gatewayUrl
output apimSubscriptions array = apimModule.outputs.apimSubscriptions
output apicServiceName string = apicModule.outputs.name

output acrLoginServer string = acaEnvModule.outputs.acrLoginServer
output acrName string = acaEnvModule.outputs.acrName
output acaEnvName string = acaEnvModule.outputs.acaEnvName

output weatherMcpUrl string = weatherAppModule.outputs.url
output catalogMcpUrl string = catalogAppModule.outputs.url
output orderMcpUrl string = orderAppModule.outputs.url

output weatherMcpApimPath string = 'weather-mcp'
output catalogMcpApimPath string = 'catalog-mcp'
output orderMcpApimPath string = 'order-mcp'
