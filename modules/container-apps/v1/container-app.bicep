// Azure Container App module
// Deploys a single container app for an MCP server

@description('Name of the container app')
param containerAppName string

@description('ACA Environment ID')
param acaEnvId string

@description('ACR login server (e.g. myacr.azurecr.io)')
param acrLoginServer string

@description('Container image name including tag (e.g. weather-mcp:latest)')
param containerImage string

@description('Location for the container app')
param location string = resourceGroup().location

@description('Container port')
param containerPort int = 8080

@description('CPU cores for the container (e.g. 0.25)')
param cpu string = '0.25'

@description('Memory in Gi for the container (e.g. 0.5Gi)')
param memory string = '0.5Gi'

@description('Min replicas')
param minReplicas int = 1

@description('Max replicas')
param maxReplicas int = 3

@description('ACR username for image pull')
param acrUsername string

@description('ACR password for image pull')
@secure()
param acrPassword string

// ------------------
//    RESOURCES
// ------------------

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: acaEnvId
    configuration: {
      ingress: {
        external: true
        targetPort: containerPort
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: acrLoginServer
          username: acrUsername
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acrPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: '${acrLoginServer}/${containerImage}'
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '20'
              }
            }
          }
        ]
      }
    }
  }
}

// ------------------
//    OUTPUTS
// ------------------
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output url string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output name string = containerApp.name
