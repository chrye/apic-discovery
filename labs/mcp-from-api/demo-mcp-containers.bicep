// ------------------
//    MCP Containers Demo — Deploy FastMCP servers as containers in Azure Container Apps
//    with APIM as the MCP gateway proxy and API Center for discoverability
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
param calculatorImage string = 'calculator-mcp:latest'

// ------------------
//    VARIABLES
// ------------------
var resourceSuffix = uniqueString(subscription().id, resourceGroup().id)

// MCP server definitions — drives container apps, APIM proxies, APIC registration, and diagnostics
var mcpServers = [
  { name: 'weather-mcp',    image: weatherImage,    mountPath: 'weather',    displayName: 'Weather MCP',         description: 'Provides city lookups and weather forecasts'                        }
  { name: 'catalog-mcp',    image: catalogImage,    mountPath: 'catalog',    displayName: 'Product Catalog MCP', description: 'Search products, list categories, and check stock'                  }
  { name: 'order-mcp',      image: orderImage,      mountPath: 'order',      displayName: 'Order Service MCP',   description: 'Place orders, track order status, and list orders'                  }
  { name: 'calculator-mcp', image: calculatorImage,  mountPath: 'calculator', displayName: 'Calculator MCP',      description: 'Math operations, square root, and unit conversions'                 }
]

// ------------------
//    RESOURCES
// ------------------

// ─── 1. Log Analytics Workspace ───
module lawModule '../../modules/operational-insights/v1/workspaces.bicep' = {
  name: 'lawModule'
}

// ─── 2. Application Insights ───
module appInsightsModule '../../modules/monitor/v1/appinsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    lawId: lawModule.outputs.id
    customMetricsOptedInType: 'WithDimensions'
  }
}

// ─── 3. API Management ───
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

// ─── 4. API Center (with MCP environment for discoverability) ───
module apicModule '../../modules/apic/v1/apic.bicep' = {
  name: 'apicModule'
  params: {
    apicServiceName: '${apicServiceNamePrefix}-${resourceSuffix}'
    location: apicLocation
  }
}

// ─── 5. Container Apps Environment + ACR ───
module acaEnvModule '../../modules/container-apps/v1/environment.bicep' = {
  name: 'acaEnvModule'
  params: {
    lawId: lawModule.outputs.id
  }
}

// ─── 6. Container Apps (one per MCP server) ───
module containerApps '../../modules/container-apps/v1/container-app.bicep' = [for server in mcpServers: {
  name: '${server.name}-app'
  params: {
    containerAppName: server.name
    acaEnvId: acaEnvModule.outputs.acaEnvId
    acrLoginServer: acaEnvModule.outputs.acrLoginServer
    containerImage: server.image
    acrUsername: acrUsername
    acrPassword: acrPassword
  }
}]

// ─── 7. APIM Streamable MCP Proxies (one per MCP server) ───
module mcpProxies '../../modules/apim-streamable-mcp/api.bicep' = [for (server, i) in mcpServers: {
  name: '${server.name}-proxy'
  params: {
    apimServiceName: apimModule.outputs.name
    MCPServiceURL: '${containerApps[i].outputs.url}/${server.mountPath}'
    MCPPath: server.name
  }
}]

// ─── 8. Application Insights Diagnostics (verbose tracing per MCP API) ───
resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimModule.outputs.name
}

resource mcpDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01' = [for (server, i) in mcpServers: {
  name: '${apimModule.outputs.name}/${server.name}-mcp-tools/applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    loggerId: resourceId(resourceGroup().name, 'Microsoft.ApiManagement/service/loggers', apimModule.outputs.name, 'appinsights-logger')
    metrics: true
    verbosity: 'verbose'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
  }
  dependsOn: [
    mcpProxies[i]
  ]
}]

// ─── 9. Register each MCP in API Center for discoverability ───
resource apiCenterService 'Microsoft.ApiCenter/services@2024-06-01-preview' existing = {
  name: apicModule.outputs.name
}

resource apiCenterWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-06-01-preview' existing = {
  parent: apiCenterService
  name: 'default'
}

resource apiCenterMCPs 'Microsoft.ApiCenter/services/workspaces/apis@2024-06-01-preview' = [for (server, i) in mcpServers: {
  parent: apiCenterWorkspace
  name: server.name
  properties: {
    title: server.displayName
    kind: 'mcp'
    lifecycleState: 'production'
    externalDocumentation: [
      {
        description: 'Install in VS Code'
        title: 'Install in VS Code'
        url: 'https://insiders.vscode.dev/redirect/mcp/install?name=${server.name}&config={"type":"sse","url":"${apim.properties.gatewayUrl}/${server.name}/mcp"}'
      }
    ]
    summary: server.description
    description: '${server.description}. Containerized FastMCP server on Azure Container Apps, proxied through APIM.'
  }
  dependsOn: [
    mcpProxies[i]
  ]
}]

resource mcpVersions 'Microsoft.ApiCenter/services/workspaces/apis/versions@2024-06-01-preview' = [for (server, i) in mcpServers: {
  parent: apiCenterMCPs[i]
  name: '1-0-0'
  properties: {
    title: '1.0.0'
    lifecycleStage: 'production'
  }
}]

resource mcpDefinitions 'Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-06-01-preview' = [for (server, i) in mcpServers: {
  parent: mcpVersions[i]
  name: '${server.name}-definition'
  properties: {
    description: '${server.displayName} definition'
    title: '${server.displayName} Definition'
  }
}]

resource mcpDeployments 'Microsoft.ApiCenter/services/workspaces/apis/deployments@2024-06-01-preview' = [for (server, i) in mcpServers: {
  parent: apiCenterMCPs[i]
  name: '${server.name}-deployment'
  properties: {
    description: '${server.displayName} deployment via APIM gateway'
    title: '${server.displayName} Deployment'
    environmentId: '/workspaces/default/environments/${apicModule.outputs.mcpEnvironmentName}'
    definitionId: '/workspaces/${apiCenterWorkspace.name}/apis/${apiCenterMCPs[i].name}/versions/${mcpVersions[i].name}/definitions/${mcpDefinitions[i].name}'
    state: 'active'
    server: {
      runtimeUri: [
        '${apim.properties.gatewayUrl}/${server.name}'
      ]
    }
  }
}]

// ─── 10. MCP Insights Dashboard ───
module mcpDashboardModule 'src/mcp-insights/dashboard.bicep' = {
  name: 'mcpDashboardModule'
  params: {
    resourceSuffix: resourceSuffix
    workspaceName: lawModule.outputs.name
    workspaceId: lawModule.outputs.id
    workbookId: guid(resourceGroup().id, resourceSuffix, 'mcp-containers-workbook')
    appInsightsId: appInsightsModule.outputs.id
    appInsightsName: appInsightsModule.outputs.applicationInsightsName
  }
}

// ------------------
//    ACR credentials (resolved from the deployed ACR)
// ------------------
var acrUsername = acr_resource.listCredentials().username
var acrPassword = acr_resource.listCredentials().passwords[0].value

resource acr_resource 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
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

output weatherMcpUrl string = containerApps[0].outputs.url
output catalogMcpUrl string = containerApps[1].outputs.url
output orderMcpUrl string = containerApps[2].outputs.url
output calculatorMcpUrl string = containerApps[3].outputs.url

output weatherMcpApimPath string = mcpServers[0].name
output catalogMcpApimPath string = mcpServers[1].name
output orderMcpApimPath string = mcpServers[2].name
output calculatorMcpApimPath string = mcpServers[3].name

output appInsightsName string = appInsightsModule.outputs.applicationInsightsName
output appInsightsId string = appInsightsModule.outputs.id
