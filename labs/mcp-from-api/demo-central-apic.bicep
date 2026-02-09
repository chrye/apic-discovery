// ========================================================
//  Central API Center — Federated Discovery Hub
//  Creates a standalone API Center that serves as the
//  central catalog for APIs discovered across distributed
//  API Centers and APIM instances
// ========================================================

// ------------------
//    PARAMETERS
// ------------------

@description('API Center name')
param apicServiceName string

@description('Location for the API Center')
param location string = resourceGroup().location

@description('API Center SKU')
param apicSku string = 'Free'

// ------------------
//    RESOURCES
// ------------------

// Central API Center Service
resource apiCenterService 'Microsoft.ApiCenter/services@2024-06-01-preview' = {
  name: apicServiceName
  location: location
  sku: {
    name: apicSku
  }
}

// Default workspace
resource apiCenterWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-06-01-preview' = {
  parent: apiCenterService
  name: 'default'
  properties: {
    title: 'Default workspace'
    description: 'Central API governance workspace'
  }
}

// Environment: REST APIs
resource apiEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'api'
  properties: {
    title: 'REST APIs'
    description: 'REST API environment'
    kind: 'rest'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// Environment: MCP Servers
resource mcpEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'mcp'
  properties: {
    title: 'MCP Servers'
    description: 'Model Context Protocol servers environment'
    kind: 'mcp'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// Environment: A2A Agents
resource a2aEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'a2a'
  properties: {
    title: 'A2A Agents'
    description: 'Agent-to-Agent protocol agents environment'
    kind: 'a2a'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// ------------------
//    OUTPUTS
// ------------------

output id string = apiCenterService.id
output name string = apiCenterService.name
output apiEnvironmentName string = apiEnvironment.name
output mcpEnvironmentName string = mcpEnvironment.name
output a2aEnvironmentName string = a2aEnvironment.name
