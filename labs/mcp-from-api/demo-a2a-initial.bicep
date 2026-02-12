// ========================================================
//  Demo: A2A Agents - Initial Deployment
//  Deploys: Log Analytics, App Insights, APIM, API Center
//           Title Agent (REST API + A2A Server)
//           Outline Agent (REST API + A2A Server)
// ========================================================

// ------------------
//    PARAMETERS
// ------------------

param apimSku string
param apimName string
param apimLocation string = resourceGroup().location
param apimSubscriptionsConfig array = []
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

// 4. API Center (includes api, mcp, and a2a environments)
module apicModule '../../modules/apic/v1/apic.bicep' = {
  name: 'apicModule'
  params: {
    apicServiceName: '${apicServiceNamePrefix}-${resourceSuffix}'
    location: apicLocation
  }
}

// 5. Title Agent - REST API
module titleAPIModule 'src/title-agent/api/api.bicep' = {
  name: 'titleAPIModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.apiEnvironmentName
  }
}

// 5b. Title Agent - A2A Server
module titleA2AModule 'src/title-agent/a2a-server/a2a.bicep' = {
  name: 'titleA2AModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.a2aEnvironmentName
    apiName: titleAPIModule.outputs.name
  }
}

// 6. Outline Agent - REST API
module outlineAPIModule 'src/outline-agent/api/api.bicep' = {
  name: 'outlineAPIModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.apiEnvironmentName
  }
}

// 6b. Outline Agent - A2A Server
module outlineA2AModule 'src/outline-agent/a2a-server/a2a.bicep' = {
  name: 'outlineA2AModule'
  params: {
    apimServiceName: apimModule.outputs.name
    apicServiceName: apicModule.outputs.name
    environmentName: apicModule.outputs.a2aEnvironmentName
    apiName: outlineAPIModule.outputs.name
  }
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
output apicA2aEnvironmentName string = apicModule.outputs.a2aEnvironmentName
output titleAgentEndpoint string = titleA2AModule.outputs.endpoint
output titleAgentCardEndpoint string = titleA2AModule.outputs.agentCardEndpoint
output outlineAgentEndpoint string = outlineA2AModule.outputs.endpoint
output outlineAgentCardEndpoint string = outlineA2AModule.outputs.agentCardEndpoint
