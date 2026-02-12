// Azure Container Apps Environment + Container Registry module
// Deploys ACR, ACA Environment (linked to LAW), and optionally an ACR build task

@description('Location for all resources')
param location string = resourceGroup().location

@description('Log Analytics Workspace ID for ACA environment')
param lawId string

@description('Unique suffix for resource naming')
param resourceSuffix string = uniqueString(subscription().id, resourceGroup().id)

@description('Name prefix for the ACA environment')
param acaEnvNamePrefix string = 'aca-env'

@description('Name prefix for the container registry')
param acrNamePrefix string = 'acr'

// ------------------
//    VARIABLES
// ------------------
var acaEnvName = '${acaEnvNamePrefix}-${resourceSuffix}'
// ACR names must be alphanumeric only
var acrName = '${replace(acrNamePrefix, '-', '')}${resourceSuffix}'

// ------------------
//    RESOURCES
// ------------------

// Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Container Apps Environment
resource acaEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: acaEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(lawId, '2023-09-01').customerId
        sharedKey: listKeys(lawId, '2023-09-01').primarySharedKey
      }
    }
  }
}

// ------------------
//    OUTPUTS
// ------------------
output acaEnvId string = acaEnv.id
output acaEnvName string = acaEnv.name
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output acrId string = acr.id

@description('ACR admin username')
output acrUsername string = acr.listCredentials().username

@description('ACR admin password')
@secure()
output acrPassword string = acr.listCredentials().passwords[0].value
