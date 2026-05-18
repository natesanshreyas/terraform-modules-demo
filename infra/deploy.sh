#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${RESOURCE_GROUP:-}" || -z "${LOCATION:-}" || -z "${NAME_PREFIX:-}" ]]; then
  echo "Set RESOURCE_GROUP, LOCATION, and NAME_PREFIX environment variables."
  exit 1
fi

az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$(dirname "$0")/main.bicep" \
  --parameters location="$LOCATION" namePrefix="$NAME_PREFIX"
