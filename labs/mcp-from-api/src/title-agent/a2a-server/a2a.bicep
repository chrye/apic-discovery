param apimServiceName string
param apicServiceName string
param apiName string = 'title-generator-api'

param a2aPath string = 'title-agent'
param a2aName string = 'title-agent'
param a2aDisplayName string = 'Title Generator A2A Agent'
param a2aDescription string = 'A2A agent for generating catchy blog post titles'

param environmentName string
param a2aLifecycleStage string = 'development'

param a2aVersionName string = '1-0-0'
param a2aVersionDisplayName string = '1.0.0'
param a2aDefinitionName string = '${a2aName}-definition'
param a2aDefinitionDisplayName string = '${a2aDisplayName} Definition'
param a2aDefinitionDescription string = '${a2aDisplayName} Definition for version ${a2aVersionName}'

param a2aDeploymentName string = '${a2aName}-deployment'
param a2aDeploymentDisplayName string = '${a2aDisplayName} Deployment'
param a2aDeploymentDescription string = '${a2aDisplayName} Deployment for version ${a2aVersionName} and environment ${environmentName}'


resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimServiceName
}

// A2A Agent API - HTTP passthrough with A2A protocol operations
resource a2aApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: apim
  name: a2aName
  properties: {
    apiType: 'http'
    displayName: a2aDisplayName
    description: a2aDescription
    apiRevision: '1'
    subscriptionRequired: false
    path: a2aPath
    protocols: [
      'https'
    ]
    isCurrent: true
  }
}

// Operation: GET /.well-known/agent.json - Agent Card Discovery
resource agentCardOperation 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: a2aApi
  name: 'get-agent-card'
  properties: {
    displayName: 'Get Agent Card'
    description: 'Returns the A2A Agent Card for discovery. The agent card contains metadata about the agent including its name, description, skills, and capabilities.'
    method: 'GET'
    urlTemplate: '/.well-known/agent.json'
    responses: [
      {
        statusCode: 200
        description: 'Agent card returned successfully'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

// Policy for Agent Card endpoint - returns static agent card JSON
resource agentCardPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  parent: agentCardOperation
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('policy-agent-card.xml')
  }
}

// Operation: POST / - A2A Message Send (JSON-RPC 2.0)
resource messageSendOperation 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: a2aApi
  name: 'message-send'
  properties: {
    displayName: 'Send Message (A2A JSON-RPC)'
    description: 'Handles A2A protocol JSON-RPC 2.0 messages. Supports the message/send method to send tasks to this agent.'
    method: 'POST'
    urlTemplate: '/'
    request: {
      representations: [
        {
          contentType: 'application/json'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'JSON-RPC response with task result'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

// Policy for message/send - calls the underlying REST API and wraps in A2A Task response
resource messageSendPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  parent: messageSendOperation
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('policy-message-send.xml')
  }
}

// A2A API-level policy with tracing
resource a2aApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  parent: a2aApi
  name: 'policy'
  properties: {
    value: loadTextContent('policy.xml')
    format: 'rawxml'
  }
}

// App Insights diagnostics
resource a2aInsights 'Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01' = {
  name: 'applicationinsights'
  parent: a2aApi
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    loggerId: resourceId(resourceGroup().name, 'Microsoft.ApiManagement/service/loggers', apimServiceName, 'appinsights-logger')
    metrics: true
    verbosity: 'verbose'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {}
    backend: {}
  }
}

// ------------------
//    API Center Registration
// ------------------

resource apiCenterService 'Microsoft.ApiCenter/services@2024-06-01-preview' existing = {
  name: apicServiceName
}

resource apiCenterWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-06-01-preview' existing = {
  parent: apiCenterService
  name: 'default'
}

resource apiCenterA2A 'Microsoft.ApiCenter/services/workspaces/apis@2024-06-01-preview' = {
  parent: apiCenterWorkspace
  name: a2aName
  properties: {
    title: a2aDisplayName
    kind: 'a2a'
    lifecycleState: a2aLifecycleStage
    externalDocumentation: [
      {
        description: a2aDescription
        title: a2aDisplayName
        url: 'https://example.com/a2a-docs'
      }
    ]
    contacts: []
    customProperties: {}
    summary: a2aDescription
    description: a2aDescription
  }
}

resource a2aVersion 'Microsoft.ApiCenter/services/workspaces/apis/versions@2024-06-01-preview' = {
  parent: apiCenterA2A
  name: a2aVersionName
  properties: {
    title: a2aVersionDisplayName
    lifecycleStage: a2aLifecycleStage
  }
}

resource a2aDefinition 'Microsoft.ApiCenter/services/workspaces/apis/versions/definitions@2024-06-01-preview' = {
  parent: a2aVersion
  name: a2aDefinitionName
  properties: {
    description: a2aDefinitionDescription
    title: a2aDefinitionDisplayName
  }
}

resource a2aDeployment 'Microsoft.ApiCenter/services/workspaces/apis/deployments@2024-06-01-preview' = {
  parent: apiCenterA2A
  name: a2aDeploymentName
  properties: {
    description: a2aDeploymentDescription
    title: a2aDeploymentDisplayName
    environmentId: '/workspaces/default/environments/${environmentName}'
    definitionId: '/workspaces/${apiCenterWorkspace.name}/apis/${apiCenterA2A.name}/versions/${a2aVersion.name}/definitions/${a2aDefinition.name}'
    state: 'active'
    server: {
      runtimeUri: [
        '${apim.properties.gatewayUrl}/${a2aPath}'
      ]
    }
  }
}

// ------------------
//    OUTPUTS
// ------------------

output name string = a2aApi.name
output endpoint string = '${apim.properties.gatewayUrl}/${a2aPath}'
output agentCardEndpoint string = '${apim.properties.gatewayUrl}/${a2aPath}/.well-known/agent.json'
