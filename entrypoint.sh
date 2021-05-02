#!/usr/bin/bash
# AZURE_CLIENT_ID=78470f79-20c1-4651-9cb5-f0999edb587
# AZURE_CLIENT_SECRET=tq6r8W-FaZ6_j.TaF-aOWLq4u_O03t~Cq0
# AZURE_SERVICE_TENANT_ID=817e531d-191b-4cf5-8812-f0061d89b53d
# TEAM_DISPLAY_NAME=AKS Team Ranger

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

saName="team-$name"
roleName="team:$name"

cat > config/role.user.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: user:dashboard:view
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
  name: user:namespaces:view
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"]
EOF