az cognitiveservices account create --kind TextAnalytics -g aks-public-rg -n text-analysis -l australiaeast --sku F0 --yes

cogServiceKey=$(az cognitiveservices account keys list -n text-analysis -g aks-public-rg --query "key1" -o tsv)

kubectl create secret generic smilr-secrets --from-literal=sentiment-key=$cogServiceKey