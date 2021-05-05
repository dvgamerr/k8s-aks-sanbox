#!/bin/bash
# AZURE_CLIENT_ID=78470f79-20c1-4651-9cb5-f0999edb587
# AZURE_CLIENT_SECRET=tq6r8W-FaZ6_j.TaF-aOWLq4u_O03t~Cq0
# AZURE_SERVICE_TENANT_ID=817e531d-191b-4cf5-8812-f0061d89b53d
# TEAM_DISPLAY_NAME=AKS Team Ranger
# TEAM_NAMESPACE=

WORKDIR=/sandbox/config
# NOTIFY='https://notice.touno.io/notify/aks/sandbox'

# if [ $AZURE_CLIENT_ID -eq "" ] then
#   exit 1
# fi

# if [ $AZURE_CLIENT_SECRET -eq "" ] then
#   exit 1
# fi

# if [ $AZURE_SERVICE_TENANT_ID -eq "" ] then
#   exit 1
# fi

labelKey="app.kubernetes.io/controller"
labelValue="assign-team"
labels="$labelKey: $labelValue"

mkdir -p $WORKDIR

# az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_SERVICE_TENANT_ID

# tsv=$(az ad group show --group "$TEAM_DISPLAY_NAME" --query "{id:objectId,name:mailNickname,mail:mail}" -o tsv)
# if [ $? -eq 0 ] then
#   exit $?
# fi
# az ad group show --group "$TEAM_DISPLAY_NAME" -o json > $WORKDIR/team-group.json

#### Example Data ####
TEAM_DISPLAY_NAME="Slick - Checkout"
TEAM_NAMESPACE="gwp-promotion"
tsv="ea696194-d9bb-411d-8349-9a29c9ea5704    SlickTEAM       SlickTEAM@central.co.th"
#### Example Data ####

display=$TEAM_DISPLAY_NAME
team="$(sed -e 's/ \| \| - \| - /-/g' <<< "${display,,}")"
name=$TEAM_NAMESPACE

if [ ["$TEAM_NAMESPACE" -eq ""] ] then
  name=$team
fi

objectId=$(echo $tsv | awk '{print $1}')
mail=$(echo $tsv | awk '{print $3}')
mail=${mail,,}

# curl -X PUT $NOTIFY -H 'Content-Type: application/json' \
#   -d "{\"message\":\"*[sandbox]* Initializing\n*TEAM:* $display ($name)\n*Email:* $mail\"}" 

saName="team-$name"
saDashboard="$saName-dashboard"
roleName="team:$name"

roleDashboardView="user:dashboard:view"
roleNamespaceView="user:namespaces:view"
cat > $WORKDIR/role.user.yaml <<EOF
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

cat > $WORKDIR/role.team.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $name
  labels:
    $labels
    team: $team
    $team: ''
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $saName
  namespace: $name
  labels:
    $labels
    team: $team
    $team: ''
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $saDashboard
  namespace: $name
  labels:
    $labels
    team: $team
    $team: ''
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $roleName:admin
  namespace: $name
  labels:
    $labels
    team: $team
    $team: ''
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
    team: $team
    $team: ''
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
    team: $team
    $team: ''
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
    team: $team
    $team: ''
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

cat > $WORKDIR/team.yaml <<EOF
image:
  repository: kubernetesui/dashboard

protocolHttp: true

ingress:
  enabled: false
  
extraArgs:
  - --namespace=$name
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

# curl -X PUT $NOTIFY -H 'Content-Type: application/json' \
#   -d "{\"message\":\"*[sandbox]* Rolebinding... \"}" 

# kubectl apply -f $WORKDIR/role.user.yaml
# kubectl apply -f $WORKDIR/role.team.yaml

# kubectl create secret generic $saName \
#   --from-file=role-user=$WORKDIR/role.user.yaml \
#   --from-file=role-team=$WORKDIR/role.team.yaml \
#   --from-file=dashboard=$WORKDIR/team.yaml

# if [ $TEAM_NAMESPACE -eq "" ] then
#   curl -X PUT $NOTIFY -H 'Content-Type: application/json' \
#     -d "{\"message\":\"*[sandbox]* Dashboard creating...\"}" 
#   helm install team -n $name -f $WORKDIR/team.yaml kubernetes-dashboard/kubernetes-dashboard
# fi

kubectl -n $team get cm/kubernetes-dashboard-settings -o json | \
  jq '.data._global | fromjson' | \
  jq -rc ".namespaceFallbackList[.namespaceFallbackList | length] |= . + \"$name\"" > _global.json