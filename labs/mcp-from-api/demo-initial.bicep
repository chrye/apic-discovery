// ========================================================
//  Demo: Initial Deployment - 3 MCP Servers
//  Deploys: Log Analytics, App Insights, APIM, API Center
//           Weather API + MCP, Product Catalog API + MCP,
//           Place Order API + MCP (with Logic App backend)
// ========================================================

// ------------------
//    PARAMETERS
// ------------------

param apimSku string
param apimName string
param apimSubscriptionsConfig array = []
param apimLocation string = resourceGroup().location
param apicLocation string = resourceGroup().location
param apicServiceNamePrefix string = 'apic'

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
    location: apimLocation
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

// 5. Weather API + MCP
module weatherAPIModule 'src/weather/api/api.bicep' = {
  name: 'weatherAPIModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.apiEnvironmentName
  }
  dependsOn: [
    apicModule
  ]
}

module weatherMCPModule 'src/weather/mcp-server/mcp.bicep' = {
  name: 'weatherMCPModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.mcpEnvironmentName
    apiName: weatherAPIModule.outputs.name
  }
  dependsOn: [
    apicModule
    weatherAPIModule
  ]
}

// 6. Product Catalog API + MCP
module productCatalogAPIModule 'src/product-catalog/api/api.bicep' = {
  name: 'productCatalogAPIModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.apiEnvironmentName
  }
  dependsOn: [
    apicModule
  ]
}

module productCatalogMCPModule 'src/product-catalog/mcp-server/mcp.bicep' = {
  name: 'productCatalogMCPModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.mcpEnvironmentName
    apiName: productCatalogAPIModule.outputs.name
  }
  dependsOn: [
    apicModule
    productCatalogAPIModule
  ]
}

// 7. Place Order API + MCP (with Logic App backend)
module placeOrderAPIModule 'src/place-order/api/api.bicep' = {
  name: 'placeOrderAPIModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.apiEnvironmentName
  }
  dependsOn: [
    apicModule
  ]
}

module placeOrderMCPModule 'src/place-order/mcp-server/mcp.bicep' = {
  name: 'placeOrderMCPModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.mcpEnvironmentName
    apiName: placeOrderAPIModule.outputs.name
  }
  dependsOn: [
    apicModule
    placeOrderAPIModule
  ]
}

// ------------------
//    OUTPUTS
// ------------------

output apimServiceId string = apimModule.outputs.id
output apimServiceName string = apimModule.outputs.name
output apimResourceGatewayURL string = apimModule.outputs.gatewayUrl
output apimSubscriptions array = apimModule.outputs.apimSubscriptions
output apicServiceName string = apicModule.outputs.name
output apicApiEnvironmentName string = apicModule.outputs.apiEnvironmentName
output apicMcpEnvironmentName string = apicModule.outputs.mcpEnvironmentName
output weatherMCPEndpoint string = weatherMCPModule.outputs.endpoint
output productCatalogMCPEndpoint string = productCatalogMCPModule.outputs.endpoint
output placeOrderMCPEndpoint string = placeOrderMCPModule.outputs.endpoint
