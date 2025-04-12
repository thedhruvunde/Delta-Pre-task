#!/bin/bash

# Create groups
addgroup g_user
addgroup g_mod
addgroup g_admin
addgroup g_author

apt install yq -y

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
        useradd -m -d "$home_dir" "$username"
        usermod -a -G $group_name $username
        echo "User $username created!"
    fi
}

get_usernames() {
    local role=$1
    awk -v role="$role" '
	$0 ~ "^" role ":" { in_role=1; next }
  	/^[a-z]+:/ { in_role=0 }
  	in_role && $1 ~ /username:/ {
    print $2}
	' "$CONFIG_FILE"
        
}


get_authors() {
    yq '.mods[] | select(.username == "'"$1"'") | .authors[]' users.yaml
}
echo "Processing Admins..."
get_usernames "admins" | while read -r username; do
    home="/home/admin/$username"
    create_user "$username" "$home" "g_admin"
done

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

author_dirs=("blogs" "public")
get_usernames "authors" | while read -r username; do
    for dir in "${author_dirs[@]}"; do
		mkdir -p "/home/authors/$username/$dir"
    done 
done


echo "Processing Moderators..."
get_usernames "mods" | while read -r username; do
    home="/home/mods/$username"
    create_user "$username" "$home" "g_mod"
done

echo "Processing User permissions..."
get_usernames "users" | while read -r username; do
    home="/home/users/$username"
    chmod 700 $home
    
done

echo "Processing admin permissions..."
get_usernames "admins" | while read -r username; do
    home="/home/admin/$username"
    chmod 700 $home
    usermod -a -G sudo
done

echo "Processing Moderators permissions..."
get_usernames "mods" | while read -r modid; do
    home="/home/mods/$modid"
    chmod 700 $home
    get_authors $modid | while read -r authorid; do
    usermod -a -G $authorid $modid
    
done

