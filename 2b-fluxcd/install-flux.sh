helm repo add fluxcd https://charts.fluxcd.io
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
kubectl create namespace flux

kubectl create secret docker-registry regcred \
    --docker-server="https://akspublicacr.azurecr.io/" \
    --docker-username="akspublicacr" \
    --docker-password="REDACTEDakspublicacr.azurecr.io" \
    --docker-email="cbellee@microsoft.com" \
    -n flux

helm upgrade -i flux fluxcd/flux \
   --set git.url=git@github.com:cbellee/flux-cd \
   --namespace flux

 helm upgrade -i helm-operator fluxcd/helm-operator \
   --set git.ssh.secretName=flux-git-deploy \
   --namespace flux \
   --set image.pullSecret=regcred \
   --set helm.versions=v3

# get public key & add to Git Repo 'Deploy Keys'
fluxctl identity --k8s-fwd-ns flux 