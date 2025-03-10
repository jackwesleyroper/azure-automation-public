#!/bin/bash

org="{ORG-NAME}"
proj="{PROJECT-NAME}"
pat="{PAT}"

az devops login --org https://dev.azure.com/$org <<EOF
$pat
EOF

repos=$(az repos list -p $proj | jq -r '.[].remoteUrl')

for repo in $repos; do
  echo "Clone repository: $repo"
  git clone "$repo"
done