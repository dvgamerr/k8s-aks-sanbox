#!/usr/bin/bash
# AZURE_CLIENT_ID=78470f79-20c1-4651-9cb5-f0999edb587
# AZURE_CLIENT_SECRET=tq6r8W-FaZ6_j.TaF-aOWLq4u_O03t~Cq0
# AZURE_SERVICE_TENANT_ID=817e531d-191b-4cf5-8812-f0061d89b53d
# TEAM_DISPLAY_NAME=AKS Team Ranger

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_SERVICE_TENANT_ID

tsv=$(az ad group show --group "$TEAM_DISPLAY_NAME" --query "{id:objectId,name:mailNickname,mail:mail}" -o tsv)
if [ $? -eq 0 ] then
  exit $?
fi
