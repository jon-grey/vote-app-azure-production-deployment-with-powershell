resource deploymentContainerGroup 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: 'string'
  location: 'string'
  tags: {}
  identity: {
    type: 'string'
    userAssignedIdentities: {}
  }
  properties: {
    containers: [
      {
        name: 'string'
        properties: {
          image: 'string'
          command: [
            'string'
          ]
          ports: [
            {
              protocol: 'string'
              port: int
            }
          ]
          environmentVariables: [
            {
              name: 'string'
              value: 'string'
              secureValue: 'string'
            }
          ]
          resources: {
            requests: {
              memoryInGB: any('number')
              cpu: any('number')
              gpu: {
                count: int
                sku: 'string'
              }
            }
            limits: {
              memoryInGB: any('number')
              cpu: any('number')
              gpu: {
                count: int
                sku: 'string'
              }
            }
          }
          volumeMounts: [
            {
              name: 'string'
              mountPath: 'string'
              readOnly: bool
            }
          ]
          livenessProbe: {
            exec: {
              command: [
                'string'
              ]
            }
            httpGet: {
              path: 'string'
              port: int
              scheme: 'string'
            }
            initialDelaySeconds: int
            periodSeconds: int
            failureThreshold: int
            successThreshold: int
            timeoutSeconds: int
          }
          readinessProbe: {
            exec: {
              command: [
                'string'
              ]
            }
            httpGet: {
              path: 'string'
              port: int
              scheme: 'string'
            }
            initialDelaySeconds: int
            periodSeconds: int
            failureThreshold: int
            successThreshold: int
            timeoutSeconds: int
          }
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: 'string'
        username: 'string'
        password: 'string'
      }
    ]
    restartPolicy: 'string'
    ipAddress: {
      ports: [
        {
          protocol: 'string'
          port: int
        }
      ]
      type: 'string'
      ip: 'string'
      dnsNameLabel: 'string'
    }
    osType: 'string'
    volumes: [
      {
        name: 'string'
        azureFile: {
          shareName: 'string'
          readOnly: bool
          storageAccountName: 'string'
          storageAccountKey: 'string'
        }
        emptyDir: {}
        secret: {}
        gitRepo: {
          directory: 'string'
          repository: 'string'
          revision: 'string'
        }
      }
    ]
    diagnostics: {
      logAnalytics: {
        workspaceId: 'string'
        workspaceKey: 'string'
        logType: 'string'
        metadata: {}
      }
    }
    networkProfile: {
      id: 'string'
    }
    dnsConfig: {
      nameServers: [
        'string'
      ]
      searchDomains: 'string'
      options: 'string'
    }
    sku: 'string'
    encryptionProperties: {
      vaultBaseUrl: 'string'
      keyName: 'string'
      keyVersion: 'string'
    }
    initContainers: [
      {
        name: 'string'
        properties: {
          image: 'string'
          command: [
            'string'
          ]
          environmentVariables: [
            {
              name: 'string'
              value: 'string'
              secureValue: 'string'
            }
          ]
          volumeMounts: [
            {
              name: 'string'
              mountPath: 'string'
              readOnly: bool
            }
          ]
        }
      }
    ]
  }
}

output ipAddress object = deploymentContainerGroup.properties.ipAddress

