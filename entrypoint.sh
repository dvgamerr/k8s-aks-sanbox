#!/usr/bin/bash
# AZURE_CLIENT_ID=78470f79-20c1-4651-9cb5-f0999edb587
# AZURE_CLIENT_SECRET=tq6r8W-FaZ6_j.TaF-aOWLq4u_O03t~Cq0
# AZURE_SERVICE_TENANT_ID=817e531d-191b-4cf5-8812-f0061d89b53d
# TEAM_DISPLAY_NAME=AKS Team Ranger

NOTIFY='https://notice.touno.io/notify/aks/sandbox'

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
name="$(sed -e 's/ \| \| - \| - /-/g' <<< "${display,,}")"

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

kubectl apply config/role.user.yaml

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
  namespace: $name
- kind: ServiceAccount
  name: $saName
  namespace: $name
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
  namespace: $name
EOF

kubectl apply config/role.team.yaml