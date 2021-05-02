#!/usr/bin/bash
# AZURE_CLIENT_ID=78470f79-20c1-4651-9cb5-f0999edb587
# AZURE_CLIENT_SECRET=tq6r8W-FaZ6_j.TaF-aOWLq4u_O03t~Cq0
# AZURE_SERVICE_TENANT_ID=817e531d-191b-4cf5-8812-f0061d89b53d
# TEAM_DISPLAY_NAME=AKS Team Ranger
# TEAM_NAMESPACE=

NOTIFY='https://notice.touno.io/notify/aks/sandbox'

if [ $AZURE_CLIENT_ID -eq "" ] then
  exit 1
fi

if [ $AZURE_CLIENT_SECRET -eq "" ] then
  exit 1
fi

if [ $AZURE_SERVICE_TENANT_ID -eq "" ] then
  exit 1
fi

labelKey="app.kubernetes.io/controller"
labelValue="assign-team"
labels="$labelKey: $labelValue"

mkdir -p ./config

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_SERVICE_TENANT_ID

tsv=$(az ad group show --group "$TEAM_DISPLAY_NAME" --query "{id:objectId,name:mailNickname,mail:mail}" -o tsv)
if [ $? -eq 0 ] then
  exit $?
fi
az ad group show --group "$TEAM_DISPLAY_NAME" -o json > config/team-group.json

display=$TEAM_DISPLAY_NAME
team="$(sed -e 's/ \| \| - \| - /-/g' <<< "${display,,}")"
name=$TEAM_NAMESPACE
if [ $TEAM_NAMESPACE -eq "" ] then
  name=$team
fi


objectId=$(echo $tsv | awk '{print $1}')
mail=$(echo $tsv | awk '{print $3}')
mail=${mail,,}

curl -X PUT $NOTIFY -H 'Content-Type: application/json' \
  -d "{\"message\":\"*[sandbox]* Initializing\n*TEAM:* $display ($name)\n*Email:* $mail\"}" 

saName="team-$name"
saDashboard="$saName-dashboard"
roleName="team:$name"

roleDashboardView="user:dashboard:view"
roleNamespaceView="user:namespaces:view"
cat > config/role.user.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $roleDashboardView
  labels:
    $labels
rules:
- apiGroups: ["", "storage.k8s.io"]
  resources: ["persistentvolumes", "storageclasses"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $roleNamespaceView
  labels:
    $labels
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"]
EOF

cat > config/role.team.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $name
  labels:
    $labels
    team: $name
    $name: ''
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $saName
  namespace: $name
  labels:
    $labels
    team: $name
    $name: ''
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $saDashboard
  namespace: $name
  labels:
    $labels
    team: $name
    $name: ''
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $roleName:admin
  namespace: $name
  labels:
    $labels
    team: $name
    $name: ''
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $roleName:admin
  namespace: $name
  labels:
    $labels
    team: $name
    $name: ''
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $roleName:admin
subjects:
- kind: Group
  name: $objectId
- kind: ServiceAccount
  name: $saDashboard
  namespace: $name
- kind: ServiceAccount
  name: $saName
  namespace: $name
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $roleName:admin
  labels:
    $labels
    team: $name
    $name: ''
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $roleDashboardView
subjects:
- kind: Group
  name: $objectId
- kind: ServiceAccount
  name: $saDashboard
  namespace: $team
- kind: ServiceAccount
  name: $saName
  namespace: $team
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $roleName:ns
  labels:
    $labels
    team: $name
    $name: ''
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $roleNamespaceView
subjects:
- kind: Group
  name: $objectId
- kind: ServiceAccount
  name: $saName
  namespace: $team
EOF

cat > config/team.yaml <<EOF
image:
  repository: kubernetesui/dashboard

protocolHttp: true
  
extraArgs:
  - --enable-skip-login

metricsScraper:
  enabled: true

rbac:
  create: false
  clusterRoleMetrics: false

serviceAccount:
  create: false
  name: $saDashboard

settings:
  clusterName: $display
  defaultNamespace: $name
  itemsPerPage: 20
  resourceAutoRefreshTimeInterval: 5
  disableAccessDeniedNotifications: true
  namespaceFallbackList:
    - $name
EOF

curl -X PUT $NOTIFY -H 'Content-Type: application/json' \
  -d "{\"message\":\"*[sandbox]* Rolebinding... \"}" 

kubectl apply -f config/role.user.yaml
kubectl apply -f config/role.team.yaml

curl -X PUT $NOTIFY -H 'Content-Type: application/json' \
  -d "{\"message\":\"*[sandbox]* Dashboard creating...\"}" 

helm install team -n $name -f config/team.yaml kubernetes-dashboard/kubernetes-dashboard

kubectl create secret generic $saName \
  --from-file=role-user=config/role.user.yaml \
  --from-file=role-team=config/role.team.yaml \
  --from-file=dashboard=config/team.yaml
