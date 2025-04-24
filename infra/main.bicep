param parHubAddressPrefix string = '10.0.0.0/24'
param parHubLocation string = 'swedencentral'

module hubNetworking 'br/public:avm/ptn/network/hub-networking:0.2.4' = {
  name: 'hubNetworkingDeployment'
  params: {
    hubVirtualNetworks: {
      hub1: {
        addressPrefixes: [parHubAddressPrefix]
        azureFirewallSettings: {
          azureSkuTier: 'Standard'
          location: parHubLocation
          publicIPAddressObject: {
            name: 'hub1PublicIp'
          }
          threatIntelMode: 'Deny'
          zones: [
            1
            2
            3
          ]
        }
        bastionHost: {
          disableCopyPaste: true
          enableFileCopy: false
          enableIpConnect: false
          enableShareableLink: false
          scaleUnits: 2
          skuName: 'Standard'
        }
        diagnosticSettings: [
          {
            eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
            eventHubName: '<eventHubName>'
            metricCategories: [
              {
                category: 'AllMetrics'
              }
            ]
            name: 'customSetting'
            storageAccountResourceId: '<storageAccountResourceId>'
            workspaceResourceId: '<workspaceResourceId>'
          }
        ]
        dnsServers: [
          '10.0.1.6'
          '10.0.1.7'
        ]
        enableAzureFirewall: true
        enableBastion: true
        enablePeering: false
        flowTimeoutInMinutes: 30
        location: parHubLocation
        lock: {
          kind: 'CanNotDelete'
          name: 'hub1Lock'
        }
        routes: [
          {
            name: 'defaultRoute'
            properties: {
              addressPrefix: '0.0.0.0/0'
              nextHopType: 'Internet'
            }
          }
        ]
        subnets: [
          {
            addressPrefix: '<addressPrefix>'
            name: 'GatewaySubnet'
          }
          {
            addressPrefix: '<addressPrefix>'
            name: 'AzureFirewallSubnet'
          }
          {
            addressPrefix: '<addressPrefix>'
            name: 'AzureBastionSubnet'
          }
        ]
        tags: {
          Environment: 'Non-Prod'
          Role: 'DeploymentValidation'
        }
        vnetEncryption: false
        vnetEncryptionEnforcement: 'AllowUnencrypted'
      }
    }
    location: parHubLocation
  }
}
