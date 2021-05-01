# AKS-Sanbox

### How to use.
```bash
az account set --subscription 5748fbf6-e421-45f1-9df6-d3656bc00760
az login --use-device-code
az aks get-credentials --resource-group rg-cg-sea-aks-sandbox --name cg-aks-sandbox
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
helm repo update
helm install kubecost kubecost/cost-analyzer -n kube-system --set kubecostToken="aW5mby5kdmdhbWVyQGdtYWlsLmNvbQ==xm343yadf98"
# helm upgrade kubecost kubecost/cost-analyzer -n kube-system

### check kubecost dashboard 
# kubectl port-forward --namespace kube-system deployment/kubecost-cost-analyzer 9090

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

helm install --name dashboard --namespace [team-name] -f k8s-dashboard.yaml kubernetes-dashboard/kubernetes-dashboard
```



### Role & Rolebinding AKS

**get ObjectId in Group**
```bash
az login --service-principal -u 78470f79-20c1-4651-9cb5-f0999edb5871 -p tq6r8W-FaZ6_j.TaF-aOWLq4u_O03t~Cq0 -t 817e531d-191b-4cf5-8812-f0061d89b53d

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

# tsv=$(az ad group show --group "AKS Team Ranger" --query "{id:objectId,name:mailNickname,mail:mail}" -o csv)
# objectId=$(echo $tsv | awk '{print $1}')
# name=$(echo $tsv | awk '{print $2}')
# display=$(echo $tsv | awk '{print $3}')
# mail=$(echo $tsv | awk '{print $4}')
display="AKS Team Ranger"
name="$(sed -e 's/\s/\-/g' <<< "${display,,}")"
objectId="6d39199b-2dd6-43f4-92d6-7874d1435285"
mail="aksteamranger@central.co.th"
mail=${mail,,}


saName="team-$name"
roleName="team:$name"

cat > ns-list.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: user:namespaces:list
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["list"]
EOF

cat > role.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $name
  labels:
    env: sandbox
    $name: ''
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $saName
  namespace: $name
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $roleName
  namespace: $name
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $roleName
  namespace: $name
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $roleName
subjects:
- kind: Group
  name: $objectId
- kind: ServiceAccount
  name: $saName
  namespace: $name
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $roleName
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: user:namespaces:list
subjects:
- kind: Group
  name: $objectId
- kind: ServiceAccount
  name: $saName
  namespace: $name
EOF


cat > team-dashboard.yaml <<EOF
image:
  repository: kubernetesui/dashboard
  tag: v2.0.3

ingress:
  enabled: true
  paths:
    - /$name
  hosts:
    - k8s.touno.io
    
extraArgs:
  - --enable-skip-login
  - --system-banner="$display"
  - --namespace=default
  - --namespace=$name
  
metricsScraper:
  enabled: false

rbac:
  create: false
  clusterRoleMetrics: false

serviceAccount:
  create: false
EOF

helm install team --namespace aks-team-ranger -f example/team-dashboard.yaml kubernetes-dashboard/kubernetes-dashboard
```


#### Task

**Copter**
[ ] สร้าง แค่ PVC ใน ss ชื่อ aks-team-ranger เพื่อเช็ค pv auto create
[ ] list ns ด้วยคำสั่ง `kubectl get ns -l aks-team-ranger` ซึ่งอาจจะใช้ verb `watch` ทำงาน

**Kat**
[ ] ปรับ azure storage จาก Hot เป็น *cool* ที่ `pvc/configfile`
[ ] ขอ service principle ที่ สามารถดึง group show `az ad group show`

**Amp**
[ ] ขอข้อมูล Azure billing info
    - Subsciption ID
    - Tenant ID
    - Client ID
    - Client Secret
    - Region Info