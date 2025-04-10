#!/bin/bash
addgroup g_user
addgroup g_mod
addgroup g_admin
addgroup g_author
create_user() {
	local username = $1
	local home_dir = $2
	local group_name = $3
	if id "$username" &>/dev/null; then
		echo "User already exits!"
	else
		useradd -m -d "$home_dir" -g "$group_name" "$username"
		echo "User Created!"
	fi
}

get_usernames() {
	local role = $1
	local CONFIG_FILE = "/scripts/users.yaml"
	grep -A 1000 "^$role:" $CONFIG_FILE | \
		awk '/^ *- name:/ { getline; print $2 }' | \
		sed '/^[a-zA-z0-9_]*$/!d'
}

echo "Processing Users..."
get_usernames "users" | while read -r username; do
	home = "/home/users/$username"
	create_user "$username" "$home" "g_user"
done
