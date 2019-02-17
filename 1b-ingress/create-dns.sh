#!/bin/bash
set -e

# Load external input variables
source ../common/vars.sh
source vars.sh

nodeResGrp=$(az aks show --resource-group $resGrp --name $aksName --query nodeResourceGroup -o tsv)
echo "...Will use resource group: $nodeResGrp"

zoneName=$(az aks show -n $aksName -g $resGrp --query "addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName" -o tsv)
echo "...Updating DNS zone: $zoneName"

publicIp=$(kubectl get svc addon-http-application-routing-nginx-ingress -n kube-system -o json | jq -r '.status.loadBalancer.ingress[0].ip')
echo "...And point $appDnsName to: $publicIp"

az network dns record-set a add-record -g $nodeResGrp -z $zoneName -n $appDnsName -a $publicIp -o table
