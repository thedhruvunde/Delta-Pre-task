#!/bin/bash
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq
yq '.mods[] | select(.username == "'"$1"'") | .authors[]' users.yaml