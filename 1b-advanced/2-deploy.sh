#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Error! Provide 'http' or 'https' to script"
    exit
fi

ingressType=$1

echo "deploy NGINX ingress controller"
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm install nginx-ingress stable/nginx-ingress \
    --namespace default \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux

echo "Deploy ingress"
kubectl apply -f ingress-$ingressType.yaml

echo "Deploy frontend"
kubectl apply -f frontend.yaml

echo "Deploy MongoDB"
kubectl apply -f mongodb.yaml

echo "Deploy Sentiment"
#kubectl apply -f extra/sentiment.yaml

echo "Data API"
kubectl apply -f data-api.yaml

# list the resources
kubectl get all -l scenario=1b

# ../common/get-url.sh $1

# set the Azure DNS A record for 'smilr.kainiindustries.net' to the current NGINX external LB IP
INGRESS_IP=$(kubectl get services --namespace default nginx-ingress-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
CURRENT_IP=$(az network dns record-set a show -g external-dns-zones-rg --zone-name kainiindustries.net --name smilr --query arecords[0].ipv4Address -otsv)
az network dns record-set a add-record --resource-group external-dns-zones-rg --zone-name kainiindustries.net --record-set-name "smilr" --ipv4-address $INGRESS_IP
az network dns record-set a remove-record --resource-group external-dns-zones-rg --zone-name kainiindustries.net --record-set-name "smilr" --ipv4-address $CURRENT_IP

#echo "Show Logs"
#kubectl logs deploy/data-api -f
