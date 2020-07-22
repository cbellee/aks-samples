NAMESPACE=dev
FLUX_NAMESPACE=flux
RG_NAME="aks-public-rg"
CLUSTER_NAME="aks-public-aks"
ACR_NAME="akspublicacr"
AZURE_DNS_ZONE_RG="external-dns-zones-rg"
AZURE_DNS_ZONE="kainiindustries.net"
AZURE_TENANT_ID=$(az account show --query '[tenantId]' -o tsv)
AZURE_SUBSCRIPTION_ID=$(az account show --query '[id]' -o tsv)
CLUSTER_MANAGED_IDENTITY_OBJECT_ID=$(az aks show -g $RG_NAME --name $CLUSTER_NAME --query '[identityProfile.[kubeletidentity.objectId]]' -o tsv)
CLUSTER_MANAGED_IDENTITY_APP_ID=$(az aks show -g $RG_NAME --name $CLUSTER_NAME --query '[identityProfile.[kubeletidentity.clientId]]' -o tsv)

echo "integrating AKS cluster $CLUSTER_NAME with ACR $ACR_NAME"
az aks update -n $CLUSTER_NAME -g $RG_NAME --attach-acr $ACR_NAME

# echo "deploy aad pod identity"
# helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
# helm install aad-pod-identity aad-pod-identity/aad-pod-identity

# echo "deploy external-dns"
# helm repo add bitnami https://charts.bitnami.com/bitnami
# helm install azure-external-dns -f values.yml bitnami/external-dns

echo "apply role assignments for DNS zone"
DNS_ZONE_RESOURCE_ID=$(az network dns zone show --name $AZURE_DNS_ZONE --resource-group $AZURE_DNS_ZONE_RG --query id --output tsv)
echo "DNS Zone ID: " $DNS_ZONE_RESOURCE_ID
az role assignment create --role "Contributor" --assignee $CLUSTER_MANAGED_IDENTITY_APP_ID --scope $DNS_ZONE_RESOURCE_ID
az role assignment list --assignee $CLUSTER_MANAGED_IDENTITY_APP_ID --scope $DNS_ZONE_RESOURCE_ID

echo "deploy NGINX ingress controller"
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm install nginx-ingress stable/nginx-ingress \
    --namespace $NAMESPACE \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux

echo "deploy flux operator"
helm repo add fluxcd https://charts.fluxcd.io
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
kubectl create namespace $FLUX_NAMESPACE

echo "deploy flux controller"
helm upgrade -i flux fluxcd/flux \
   --set git.url=git@github.com:cbellee/flux-cd \
   --set git.path=clusters/dev \
   --namespace $FLUX_NAMESPACE

echo "deploy helm controller"
 helm upgrade -i helm-operator fluxcd/helm-operator \
   --set git.ssh.secretName=flux-git-deploy \
   --namespace $FLUX_NAMESPACE \
   --set helm.versions=v3

echo "display public key & add to Git Repo 'Deploy Keys'"
fluxctl identity --k8s-fwd-ns $FLUX_NAMESPACE
