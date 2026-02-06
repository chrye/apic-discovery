// ========================================================
//  Demo: Add Calculator MCP Server (Add-on)
//  Deploys the Calculator API + MCP into an existing
//  APIM + API Center to demonstrate auto-discoverability
// ========================================================

// ------------------
//    PARAMETERS
// ------------------

param apimServiceName string
param apicServiceName string
param apicApiEnvironmentName string
param apicMcpEnvironmentName string

// ------------------
//    RESOURCES
// ------------------

// Calculator REST API
module calculatorAPIModule 'src/calculator/api/api.bicep' = {
  name: 'calculatorAPIModule'
  params: {
    apimServiceName: apimServiceName
    apicServiceName: apicServiceName
    environmentName: apicApiEnvironmentName
  }
}

// Calculator MCP Server
module calculatorMCPModule 'src/calculator/mcp-server/mcp.bicep' = {
  name: 'calculatorMCPModule'
  params: {
    apimServiceName: apimServiceName
    apicServiceName: apicServiceName
    environmentName: apicMcpEnvironmentName
    apiName: calculatorAPIModule.outputs.name
  }
}

// ------------------
//    OUTPUTS
// ------------------

output calculatorMCPEndpoint string = calculatorMCPModule.outputs.endpoint
