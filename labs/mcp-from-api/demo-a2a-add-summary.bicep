// ========================================================
//  Demo: Add Summary A2A Agent (Add-on)
//  Deploys the Summary Agent REST API + A2A Server into an
//  existing APIM + API Center to demonstrate auto-discovery
// ========================================================

// ------------------
//    PARAMETERS
// ------------------

param apimServiceName string
param apicServiceName string
param apicApiEnvironmentName string
param apicA2aEnvironmentName string

// ------------------
//    RESOURCES
// ------------------

// Summary Agent - REST API
module summaryAPIModule 'src/summary-agent/api/api.bicep' = {
  name: 'summaryAPIModule'
  params: {
    apimServiceName: apimServiceName
    apicServiceName: apicServiceName
    environmentName: apicApiEnvironmentName
  }
}

// Summary Agent - A2A Server
module summaryA2AModule 'src/summary-agent/a2a-server/a2a.bicep' = {
  name: 'summaryA2AModule'
  params: {
    apimServiceName: apimServiceName
    apicServiceName: apicServiceName
    environmentName: apicA2aEnvironmentName
    apiName: summaryAPIModule.outputs.name
  }
}

// ------------------
//    OUTPUTS
// ------------------

output summaryAgentEndpoint string = summaryA2AModule.outputs.endpoint
output summaryAgentCardEndpoint string = summaryA2AModule.outputs.agentCardEndpoint
