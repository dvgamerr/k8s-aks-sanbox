# AKS-Sanbox

### Installation

#### Resource Summary weekly
- kubecost `http://sandbox.aks-cost.central.co.th/`
  - cost per namespace
  - cost total in cluster


```bash
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo update
helm install kubecost kubecost/cost-analyzer -n kube-system --set kubecostToken="aW5mby5kdmdhbWVyQGdtYWlsLmNvbQ==xm343yadf98"
# helm upgrade kubecost kubecost/cost-analyzer -n kube-system

# check kubecost dashboard 
kubectl port-forward --namespace kube-system deployment/kubecost-cost-analyzer 9090


```



### Role & Rolebinding AKS

**get ObjectId in Group**
```bash
tsv=$(az ad group show --group "AKS Team Ranger" --query "{id:objectId,name:mailNickname,mail:mail}" -o tsv)
objectId=$(echo $tsv | awk '{print $1}')
name=$(echo $tsv | awk '{print $2}')
mail=$(echo $tsv | awk '{print $3}')
```

get ObjectId in User
```bash
az ad group member list --group AZ_PRODUCTMGMT_TEAM --query "[?contains(mail,'ThKananek@central.co.th')].objectId" -o tsv
```

Role 
```bash
namespace="AKSTeamRanger"

tsv=$(az ad group show --group "AKS Team Ranger" --query "{id:objectId,name:mailNickname,mail:mail}" -o tsv)
objectId=$(echo $tsv | awk '{print $1}')
name=$(echo $tsv | awk '{print $2}')
mail=$(echo $tsv | awk '{print $3}')

saName="aks::team::$name"
roleName="team::$name"

cat > role.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $saName
  namespace: $namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $roleName
  namespace: $namespace
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $roleName
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $roleName
  namespace: $namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $roleName
subjects:
- kind: Group
  name: $objectId
- kind: ServiceAccount
  name: $saName
  namespace: $namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $roleName
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $roleName
subjects:
- kind: Group
  name: $objectId
- kind: ServiceAccount
  name: $saName
  namespace: $namespace
EOF
```
