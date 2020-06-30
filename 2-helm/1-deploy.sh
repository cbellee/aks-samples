#!/bin/bash
RELEASE_NAME=smilr-helm

# install nginx ingress controller
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install $RELEASE_NAME-ingress nginx-stable/nginx-ingress

az aks update -n aks-public-aks -g aks-public-rg --attach-acr akspublicacr

# install app containers
helm install $RELEASE_NAME ./smilr -f myvalues.yaml

# re-create DNS record for ingress IP
INGRESS_IP=$(kubectl get services --namespace default $RELEASE_NAME-ingress-nginx-ingress --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
az network dns record-set a delete --resource-group external-dns-zones-rg --zone-name kainiindustries.net --name $RELEASE_NAME --yes
az network dns record-set a add-record --resource-group external-dns-zones-rg --zone-name kainiindustries.net --record-set-name $RELEASE_NAME --ipv4-address $INGRESS_IP

curl http://smilr-helm.kainiindustries.net