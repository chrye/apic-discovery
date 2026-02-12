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

// Environment: REST APIs — Production
resource apiProdEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'api-prod'
  properties: {
    title: 'REST APIs — Production'
    description: 'Production REST API environment'
    kind: 'rest'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// Environment: REST APIs — Staging
resource apiStagingEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'api-staging'
  properties: {
    title: 'REST APIs — Staging'
    description: 'Staging REST API environment'
    kind: 'rest'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// Environment: MCP Servers — Production
resource mcpProdEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'mcp-prod'
  properties: {
    title: 'MCP Servers — Production'
    description: 'Production Model Context Protocol servers environment'
    kind: 'mcp'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// Environment: MCP Servers — Staging
resource mcpStagingEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'mcp-staging'
  properties: {
    title: 'MCP Servers — Staging'
    description: 'Staging Model Context Protocol servers environment'
    kind: 'mcp'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// Environment: A2A Agents — Production
resource a2aProdEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'a2a-prod'
  properties: {
    title: 'A2A Agents — Production'
    description: 'Production Agent-to-Agent protocol agents environment'
    kind: 'a2a'
    server: {
      managementPortalUri: [
        'https://portal.azure.com/'
      ]
      type: 'other'
    }
  }
}

// Environment: A2A Agents — Staging
resource a2aStagingEnvironment 'Microsoft.ApiCenter/services/workspaces/environments@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: 'a2a-staging'
  properties: {
    title: 'A2A Agents — Staging'
    description: 'Staging Agent-to-Agent protocol agents environment'
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
output apiProdEnvironmentName string = apiProdEnvironment.name
output apiStagingEnvironmentName string = apiStagingEnvironment.name
output mcpProdEnvironmentName string = mcpProdEnvironment.name
output mcpStagingEnvironmentName string = mcpStagingEnvironment.name
output a2aProdEnvironmentName string = a2aProdEnvironment.name
output a2aStagingEnvironmentName string = a2aStagingEnvironment.name
