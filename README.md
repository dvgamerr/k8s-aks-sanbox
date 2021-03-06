# AKS-Sanbox

### How to use.
```bash
az account set --subscription 5748fbf6-e421-45f1-9df6-d3656bc00760
az login --use-device-code

# Sandbox
az aks get-credentials --resource-group rg-cg-sea-aks-sandbox --name cg-aks-sandbox

# UAT
az aks get-credentials --resource-group rg-cg-sea-aks-nonprd --name cg-aks-nonprd

# Prd
az aks get-credentials --resource-group rg-cg-sea-aks-prd --name cg-aks-prd

```

### Installation

#### Resource Summary
- kubecost `https://sandbox.aks-cost.central.co.th/`
  - cost per namespace
  - cost total in cluster
  - summary usage email weekly (monthly in production)
- kubernates-dashboard `https://sandbox.aks-dashboard.central.co.th/[team-name]`


```bash

helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo add jetstack https://charts.jetstack.io
helm repo update  


helm install kubecost -n kube-system kubecost/cost-analyzer --set kubecostToken="aW5mby5kdmdhbWVyQGdtYWlsLmNvbQ==xm343yadf98"
# helm upgrade kubecost -n kube-system kubecost/cost-analyzer

### check kubecost dashboard 
# kubectl port-forward --namespace kube-system deployment/kubecost-cost-analyzer 9090

helm install dash -n kube-public --set controller.ingressClass=dashboard ingress-nginx/ingress-nginx

# disabled cert
kubectl label namespace default cert-manager.io/disable-validation=true
kubectl label namespace kube-node-lease cert-manager.io/disable-validation=true
kubectl label namespace kube-public cert-manager.io/disable-validation=true
kubectl label namespace kube-sentinel cert-manager.io/disable-validation=true
kubectl label namespace kube-system cert-manager.io/disable-validation=true

#cert-manager
helm install cert-manager -n kube-public jetstack/cert-manager --version v0.13.0

# Ingress TOUNO.io
helm install k8s -n kube-public haproxytech/kubernetes-ingress --set controller.service.type=LoadBalancer --set controller.ingressClass=touno-io
```

### Role & Rolebinding AKS

**get ObjectId in Group**
```bash
az login --service-principal -u 78470f79-20c1-4651-9cb5-f0999edb5871 -p tq6r8W-FaZ6_j.TaF-aOWLq4u_O03t~Cq0 -t 817e531d-191b-4cf5-8812-f0061d89b53d

tsv=$(az ad group show --group "Product - SlickAdmin" --query "{id:objectId,name:mailNickname,mail:mail}" -o tsv)
```
{
  "id": "660f0f15-f803-48bd-9061-a5de8871824c",
  "mail": "ProductTeam-SlickAdmin@central.co.th",
  "name": "ProductTeam-SlickAdmin"
}
Role 
```bash
display="Product - Slick Admin"
name="$(sed -e 's/ \| \| - \| - /-/g' <<< "${display,,}")"
objectId="660f0f15-f803-48bd-9061-a5de8871824c"
mail="ProductTeam-SlickAdmin@central.co.th"
mail=${mail,,}

helm install team -n aks-team-ranger -f team.yaml kubernetes-dashboard/kubernetes-dashboard
```


#### Task

**Copter**
[ ] ??????????????? ????????? PVC ?????? ss ???????????? aks-team-ranger ??????????????????????????? pv auto create
[ ] list ns ?????????????????????????????? `kubectl get ns -l aks-team-ranger` ???????????????????????????????????? verb `watch` ???????????????

**Kat**
[ ] ?????? service principle ????????? ??????????????????????????? group show `az ad group show`
