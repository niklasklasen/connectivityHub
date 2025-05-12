targetScope = 'subscription'

param parHubAddressPrefix string = '10.0.0.0/24'
param parHubLocation string = 'swedencentral'
param parDeployLogAnalyticsWorkspace bool = true
param parDeployPrivetDnsZones bool = true
param parDeployAvnm bool = true
param parLogAnalyticsWorkspaceResourceId string = ''
param parConHubLogAnalyticsWorkspaceName string = 'p-conHub-law'
param parLogResourceGroupName string = 'p-conHub-logs-rg'
param parHubResourceGroupName string = 'p-conHub-hub-rg'
param parPrivateDnsResourceGroupName string = 'p-conHub-privateDns-rg'
param parAvnmResourceGroupName string = 'p-conHub-avnm-rg'
param parBastionHostName string = 'p-conHub-bastion'
param parAzureFirewallName string = 'p-conHub-afw'
param parAzureFirewallPublicIpName string = 'p-conHub-afw-pip'
param parHubRouteTableName string = 'p-conHub-rt'
param parHubVnetName string = 'p-conHub-vnet'
param parAvnmName string = 'p-conHub-avnm'
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param parAzureFirewallSku string = 'Standard'
param parAzureFirewallPolicyName string = 'p-conHub-afw-afwp'
param parNetworkManagerScopeAccesses array = [
  'SecurityAdmin'
  'Routing'
  'Connectivity'
]
param parNetworkManagerScopes object = {
  subscriptions: [
    '/subscriptions/277fa68f-7cba-4e42-8f33-489df4796855'
  ]
}


module modResourceGroupLog 'br/public:avm/res/resources/resource-group:0.4.1' = if (parDeployLogAnalyticsWorkspace) {
  name: 'resourceGroupLogDeployment'
  params: {
    name: parLogResourceGroupName
    location: parHubLocation
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}

module modResourceGroupHub 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'resourceGroupHubDeployment'
  params: {
    name: parHubResourceGroupName
    location: parHubLocation
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}

module modResourceGroupPrivateDns 'br/public:avm/res/resources/resource-group:0.4.1' = if (parDeployPrivetDnsZones) {
  name: 'resourceGroupPrivateDnsDeployment'
  params: {
    name: parPrivateDnsResourceGroupName
    location: parHubLocation
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}

module modResourceGroupAvnm 'br/public:avm/res/resources/resource-group:0.4.1' = if (parDeployAvnm) {
  name: 'resourceGroupAvnmDeployment'
  params: {
    name: parAvnmResourceGroupName
    location: parHubLocation
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}

module modLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.11.1' = if (parDeployLogAnalyticsWorkspace) {
  name: 'logAnalyticsWorkspaceDeployment'
  scope: resourceGroup(parLogResourceGroupName  )
  dependsOn: [modResourceGroupLog]
  params: {
    name: parConHubLogAnalyticsWorkspaceName
    location: parHubLocation
    skuName: 'PerGB2018'
    lock: {
      kind: 'CanNotDelete'
      name: 'CanNotDelete-Lock'
    }
  }
}

module modFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.1' = {
  name: 'firewallPolicyDeployment'
  dependsOn: [modResourceGroupHub]
  scope: resourceGroup(parHubResourceGroupName)
  params: {
    name: parAzureFirewallPolicyName
    lock: {
      kind: 'CanNotDelete'
      name: 'CanNotDelete-Lock'
    }
    allowSqlRedirect: true
    ruleCollectionGroups: [
      {
        name: 'rule-001' // Rule Collection Group Name
        priority: 5000
        ruleCollections: [
          {
            action: {
              type: 'Allow'
            }
            name: 'collection002' // Rule Collection Name
            priority: 5555
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              {
                destinationAddresses: [
                  '*'
                ]
                destinationFqdns: []
                destinationIpGroups: []
                destinationPorts: [
                  '80'
                ]
                ipProtocols: [
                  'TCP'
                  'UDP'
                ]
                name: 'rule002' // Rule Name
                ruleType: 'NetworkRule'
                sourceAddresses: [
                  '*'
                ]
                sourceIpGroups: []
              }
            ]
          }
        ]
      }
    ]
    snat: {
      autoLearnPrivateRanges: 'Enabled'
    }
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
    threatIntelMode: 'Deny'
  }
}

module modHubNetworking 'br/public:avm/ptn/network/hub-networking:0.2.4' = {
  name: 'hubNetworkingDeployment'
  scope: resourceGroup(parHubResourceGroupName)
  dependsOn: [modResourceGroupHub]
  params: {
    hubVirtualNetworks: {       
      '${parHubVnetName}': {
        addressPrefixes: [parHubAddressPrefix]
        azureFirewallSettings: {
          azureFirewallName: parAzureFirewallName
          azureSkuTier: parAzureFirewallSku
          location: parHubLocation
          publicIPAddressObject: {
            name: parAzureFirewallPublicIpName
          }
          firewallPolicyId: modFirewallPolicy.outputs.resourceId
          threatIntelMode: 'Deny'
          zones: [
            1
            2
            3
          ]
        }
        bastionHost: {
          bastionHostName: parBastionHostName
          disableCopyPaste: true
          enableFileCopy: false
          enableIpConnect: false
          enableShareableLink: false
          scaleUnits: 2
          skuName: 'Standard'
        }
        diagnosticSettings: [
          {
            metricCategories: [
              {
                category: 'AllMetrics'
              }
            ]
            name: 'All-logs-to-conHub-law'
            workspaceResourceId: modLogAnalyticsWorkspace.outputs.resourceId ?? parLogAnalyticsWorkspaceResourceId
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
          name: 'CanNotDelete-Lock'
        }
        routeTableName: parHubRouteTableName
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
            addressPrefix: '10.0.0.0/26'
            name: 'GatewaySubnet'
          }
          {
            addressPrefix: '10.0.0.64/26'
            name: 'AzureFirewallSubnet'
          }
          {
            addressPrefix: '10.0.0.224/27'
            name: 'AzureBastionSubnet'
          }
          {
            addressPrefix: '10.0.0.128/26'
            name: 'AzureFirewallManagementSubnet'
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
  }
}

module modPrivateLinkPrivateDnsZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.4.0' = if (parDeployPrivetDnsZones) {
  scope: resourceGroup(parPrivateDnsResourceGroupName)
  name: 'privateLinkPrivateDnsZonesDeployment'
  params: {
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: modHubNetworking.outputs.hubVirtualNetworks[0].resourceId
      }
    ]
  }
}

module modNetworkManager 'br/public:avm/res/network/network-manager:0.5.2' = if (parDeployAvnm) {
  scope: resourceGroup(parAvnmResourceGroupName)
  dependsOn: [modResourceGroupAvnm]
  name: 'avnmDeployment'
  params: {
    name: parAvnmName
    networkManagerScopes: parNetworkManagerScopes
    // Non-required parameters
    networkManagerScopeAccesses: parNetworkManagerScopeAccesses
    tags: {
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}
