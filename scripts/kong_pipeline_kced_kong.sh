#!/bin/zsh

if [[ "$KONG_ENV" == "konnect" ]] then
  echo -e "*** Hello to Kong Konnect publishing pipeline"
  echo -e "If you want to use local Kong Enterprise instead, please set the KONG_ENV variable to local"
  echo -e "Please make sure you have the env variables set:"
  echo -e " - KONNECT_API_TOKEN (e.g. kpat_xxxxxxxxxx)"
  echo -e " - KONNECT_REGION (either us or eu based on your Konnect tenant)"
  echo -e " - KONNECT_RUNTIME_GROUP_NAME (e.g. default)"
  echo -e " - PROXY_URL (e.g. http://localhost:8000)"
  unset DECK_KONG_ADDR
  konnect="true"
else
  echo -e "*** Hello to self hosted Kong Enterprise publishing pipeline"
  echo -e "If you want to use Konnect instead, please set the KONG_ENV variable to konnect"
  echo -e "Please make sure you have the env variables set:"
  echo -e " - ADMIN_URL (e.g. http://localhost:8001)"
  echo -e " - PROXY_URL (e.g. http://localhost:8000)"
  DECK_KONG_ADDR=$ADMIN_URL
  konnect="false"
fi

echo -e "Press enter to start"
read

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "\n 💡 Press enter after each numbered step to execute it \n"

echo -e "${RED}**** 1) ✍  The specification is being created and agreed on using Insomnia${NC}\n"
read

echo -e "${RED}**** 2) ⌨️  The specification has been added to the development branch on GitHub\n - checking it out${NC}"
read
echo -e "${GREEN}git clone https://github.com/svenwal/uuid-generator-service.git${NC}"
git clone https://github.com/svenwal/uuid-generator-service.git
cd uuid-generator-service
git checkout development
echo -e "${RED}** Linting the spec file${NC}"
echo -e "${GREEN}inso lint spec uuid-generator.yaml${NC}"
inso lint spec uuid-generator.yaml

echo -e "\n${RED}**** 3) 🧪 Backend has been created, automated test it against OpenAPI specification${NC}\n"
read
echo -e "${GREEN}inso run test \"UUID tests\" --env \"OpenAPI env\"${NC}"
inso run test "UUID tests" --env "OpenAPI env"

echo -e "${RED}**** 4) 🐾 After tests have been successful development branch is merged into main which starts the trigger on publishing the backend to production${NC}"
read
echo -e "${GREEN}git checkout main${NC}"
git checkout main

echo -e "\n${RED}**** 5) 🦍 Backend deployed, now Kong is configureds to expose the service by converting the specification to a decK YAML file and applying it. This also includes an auto-added default plugin config from the repository${NC}"
read
echo -e "${GREEN}kced openapi2kong --spec ./uuid-generator.yaml --output-file kong-uuid-generator.yaml${NC}"
kced openapi2kong --spec ./uuid-generator.yaml --output-file kong-uuid-generator.yaml

if [ "$konnect" ]; then
  unset DECK_KONG_ADDR
  echo -e "${RED}** importing${NC}"
  yq -i eval ".services[0].tags += \"_KonnectService:UUID\"" kong-uuid-generator.yaml
  echo -e "${GREEN}deck sync --konnect-addr=https://$KONNECT_REGION.api.konghq.com --konnect-token xxxxxxxxx --konnect-runtime-group-name $KONNECT_RUNTIME_GROUP_NAME --select-tag OAS3_import -s kong-uuid-generator.yaml${NC}"
  deck sync --konnect-addr "https://$KONNECT_REGION.api.konghq.com" --konnect-runtime-group-name "$KONNECT_RUNTIME_GROUP_NAME" --konnect-token $KONNECT_API_TOKEN  --select-tag OAS3_import -s kong-uuid-generator.yaml
else
  echo -e "${RED}** Validating if file is correct${NC}"
  echo -e "${GREEN}deck --kong-addr=$ADMIN_URL validate -s kong-uuid-generator.yaml${NC}"
  deck validate --kong-addr=$ADMIN_URL -s kong-uuid-generator.yaml
  echo -e "${RED}** importing${NC}"
  echo -e "${GREEN}deck sync --kong-addr=$ADMIN_URL --select-tag OAS3_import -s kong-uuid-generator.yaml${NC}"
  deck sync --kong-addr=$ADMIN_URL --select-tag OAS3_import -s kong-uuid-generator.yaml
fi

echo -e "\n${RED}**** 6) 📄 Documentation is published to developer portal, OpenAPI endpoint changed to gateway instead of direct service url${NC}"
read
cp uuid-generator.yaml uuid-generator-gateway.yaml
yq -i eval ".servers[0].url = \"$PROXY_URL\"" uuid-generator-gateway.yaml

if [ "$konnect" ]; then
  echo -e "Importing to Konnect"
  sleep 5
  allServices=$(http https://$KONNECT_REGION.api.konghq.com/konnect-api/api/v1/service_packages Authorization:"Bearer $KONNECT_API_TOKEN")
  service=$(echo $allServices | jq -r '.data[] | select(.name == "UUID")')
  versionId=$(echo $service | jq -r '.versions[0].id')
  portalId=$(http https://$KONNECT_REGION.api.konghq.com/konnect-api/api/portals Authorization:"Bearer $KONNECT_API_TOKEN" | jq -r '.data[0].id')
  serviceId=$(echo $service | jq -r '.id')
  http --quiet PUT https://$KONNECT_REGION.api.konghq.com/konnect-api/api/service_packages/$serviceId/portals/$portalId Authorization:"Bearer $KONNECT_API_TOKEN"
  http --quiet POST https://$KONNECT_REGION.api.konghq.com/konnect-api/api/service_versions/$versionId/documents path="/uuid.yaml" published=true content=@uuid-generator-gateway.yaml Authorization:"Bearer $KONNECT_API_TOKEN"
else
  echo -e "${GREEN}http $ADMIN_URL/files path=specs/uuid-generator.yaml contents=@uuid-generator-gateway.yaml${NC}"
  http $ADMIN_URL/files path=specs/uuid-generator.yaml contents=@uuid-generator-gateway.yaml
fi
  
echo -e "\n${RED}**** 7) 🗑️  Press enter to revert all changes - cleaning up...${NC}"
echo -e "${GREEN}Press enter to delete temp files, remove decK synced files from Kong, and delete Dev Portal UUID specification${NC}"
read
if [ "$konnect" ]; then
  unset DECK_KONG_ADDR
  deck reset --force  --konnect-addr "https://$KONNECT_REGION.api.konghq.com" --konnect-runtime-group-name "$KONNECT_RUNTIME_GROUP_NAME" --konnect-token $KONNECT_API_TOKEN --select-tag OAS3_import
  rm -Rf ../uuid-generator-service
  http --quiet DELETE https://$KONNECT_REGION.api.konghq.com/konnect-api/api/service_packages/$serviceId Authorization:"Bearer $KONNECT_API_TOKEN"
else
  echo -e "${GREEN}rm -Rf ../uuid-generator-service${NC}"
  echo -e "${GREEN}http DELETE $ADMIN_URL/files/specs/uuid-generator.yaml --quiet${NC}"
  echo -e "${GREEN}deck reset --select-tag OAS3_import${NC}"
  rm -Rf ../uuid-generator-service
  http --quiet DELETE $ADMIN_URL/files/specs/uuid-generator.yaml
  deck reset --force --select-tag "OAS3_import"
fi