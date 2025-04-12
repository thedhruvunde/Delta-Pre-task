#!/bin/bash
yq '.mods[] | select(.username == "'"$1"'") | .authors[]' users.yaml