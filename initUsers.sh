#!/bin/bash

# Create groups
addgroup g_user
addgroup g_mod
addgroup g_admin
addgroup g_author


home_dirs=("admin" "users" "mods" "authors")
for dir in "${home_dirs[@]}"; do
    mkdir -p "/home/$dir"
    echo "$dir directory created"
done


CONFIG_FILE="/scripts/users.yaml"


create_user() {
    local username=$1
    local home_dir=$2
    local group_name=$3

    if id "$username" &>/dev/null; then
        echo "User $username already exists!"
    else
        useradd -m -d "$home_dir" -g "$group_name" "$username"
        usermod -a -G $group_name $username
        echo "User $username created!"
    fi
}


get_usernames() {
    local role=$1
    grep -A 1000 "^$role:" "$CONFIG_FILE" | \
        awk '/^ *- name:/ { getline; print $2 }' | \
        sed '/^[a-zA-Z0-9_]*$/!d'
        
}


echo "Processing Users..."
get_usernames "users" | while read -r username; do
    home="/home/users/$username"
    create_user "$username" "$home" "g_user"
done


echo "Processing Authors..."
get_usernames "authors" | while read -r username; do
    home="/home/authors/$username"
    create_user "$username" "$home" "g_author"
done

echo "Processing Admins..."
get_usernames "admin" | while read -r username; do
    home="/home/admin/$username"
    create_user "$username" "$home" "g_admin"
done


echo "Processing Moderators..."
get_usernames "mods" | while read -r username; do
    home="/home/mods/$username"
    create_user "$username" "$home" "g_mod"
done
