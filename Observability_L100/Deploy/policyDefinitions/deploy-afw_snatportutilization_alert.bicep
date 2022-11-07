// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'managementGroup'

param policyLocation string = 'centralus'
param deploymentRoleDefinitionIds array = [
    '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
]

module SNATPortUtilizationAlert '../../arm/Microsoft.Authorization/policyDefinitions/managementGroup/deploy.bicep' = {
  name: '${uniqueString(deployment().name)}-afwsnatportutilization-policyDefinitions'
  params: {
      name: 'Deploy_AFW_SNATPortUtilization_Alert'
      displayName: '[DINE] Deploy AFW SNATPortUtilization Alert'
      description: 'DINE policy to audit/deploy Azure Firewall SNATPortUtilization Alert'
      location: policyLocation
      metadata: {
          version: '1.0.0'
          Category: 'Networking'
          source: 'https://github.com/Azure/ALZ-Monitor/'
      }
      policyRule: {
          if: {
              allOf: [
                  {
                      field: 'type'
                      equals: 'Microsoft.Network/azureFirewalls'
                  }
              ]
          }
          then: {
              effect: 'deployIfNotExists'
              details: {
                  roleDefinitionIds: deploymentRoleDefinitionIds
                  type: 'Microsoft.Insights/metricAlerts'
                  existenceCondition: {
                      allOf: [
                          {
                              field: 'Microsoft.Insights/metricAlerts/criteria.Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria.allOf[*].metricNamespace'
                              equals: 'Microsoft.Network/azureFirewalls'
                          }
                          {
                              field: 'Microsoft.Insights/metricAlerts/criteria.Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria.allOf[*].metricName'
                              equals: 'SNATPortUtilization'
                          }
                          {
                              field: 'Microsoft.Insights/metricalerts/scopes[*]'
                              equals: '[concat(subscription().id, \'/resourceGroups/\', resourceGroup().name, \'/providers/Microsoft.Network/azureFirewalls/\', field(\'fullName\'))]'
                          }
                      ]
                  }
                  deployment: {
                      properties: {
                          mode: 'incremental'
                          template: {
                              '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
                              contentVersion: '1.0.0.0'
                              parameters: {
                                  resourceName: {
                                      type: 'String'
                                      metadata: {
                                          displayName: 'resourceName'
                                          description: 'Name of the resource'
                                      }
                                  }
                                  resourceId: {
                                      type: 'String'
                                      metadata: {
                                          displayName: 'resourceId'
                                          description: 'Resource ID of the resource emitting the metric that will be used for the comparison'
                                      }
                                  }
                              }
                              variables: {}
                              resources: [ 
                              {
                                      type: 'Microsoft.Insights/metricAlerts'
                                      apiVersion: '2018-03-01'
                                      name: '[concat(parameters(\'resourceName\'), \'-SNATPortUtilization\')]'
                                      location: 'global'
                                      properties: {
                                          description: 'Metric Alert for AFW SNATPortUtilization'
                                          severity: 3
                                          enabled: true
                                          scopes: [
                                              '[parameters(\'resourceId\')]'
                                          ]
                                          evaluationFrequency: 'PT5M'
                                          windowSize: 'PT5M'
                                          criteria: {
                                              allOf: [
                                                  {
                                                      name: 'SNATPortUtilization'
                                                      metricNamespace: 'Microsoft.Network/azureFirewalls'
                                                      metricName: 'SNATPortUtilization'
                                                      operator: 'GreaterThan'
                                                      threshold: 80
                                                      timeAggregation: 'Average'
                                                      criterionType: 'StaticThresholdCriterion'
                                                  }
                                              ]
                                              'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
                                          }
                                      }

                                  }
                              ]
                          }
                          parameters: {
                              resourceName: {
                                  value: '[field(\'name\')]'
                              }
                              resourceId: {
                                  value: '[field(\'id\')]'
                              }
                          }
                      }
                  }
              }
          }
      }
  }
}
