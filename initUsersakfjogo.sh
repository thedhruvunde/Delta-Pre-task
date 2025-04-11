#!/bin/bash

addgroup g_user
addgroup g_admin
addgroup g_mod
addgroup g_author

CONFIG_FILE="/scripts/sysad-1-users.yaml"

createUser() {
	username=$1
	userHome=$2
	group=$3
	role=$4

	if id "$username" &>/dev/null; then
		echo "User $username already exists."
	else
		useradd -m -d "$userHome" -s /bin/bash "$username"
		mkdir -p "$userHome"
		usermod -a -G "$group" "$username"
		chown "$username:$group" "$userHome"
		echo "Created user: $username group: $group with home: $userHome"
	fi
}

parseUsers(){
	role=$1
	awk -v role="$role" '
	$0 ~ "^" role ":" { in_role=1; next }
	/^[a-z]+:/ { in_role=0 }
	in_role && $1 ~ /username:/ {
	print $2 }' "$CONFIG_FILE"
}

# --- 1. Create users ---
parseUsers "admins" | while read -r user; do
	HomeDir="/home/admin/$user"
	createUser "$user" "$HomeDir" "g_admin" "admin"
done

parseUsers "users" | while read -r user; do
	HomeDir="/home/users/$user"
	createUser "$user" "$HomeDir" "g_user" "users"
done

parseUsers "authors" | while read -r user; do
	HomeDir="/home/authors/$user"
	createUser "$user" "$HomeDir" "g_author" "author"

	subDirs=("blogs" "public")
	for dir in "${subDirs[@]}"; do
		mkdir -p "$HomeDir/$dir"
		chown "$user:g_author" "$HomeDir/$dir"
	done
	echo "Author $user directories created"
done

parseUsers "mods" | while read -r user; do
	HomeDir="/home/mods/$user"
	createUser "$user" "$HomeDir" "g_mod" "mods"
done

# --- 2. Directory Permissions ---
# Restrict access: only user/author can access their own home directory
chmod -R o-rwx /home/users
chmod -R o-rwx /home/authors

for user in $(parseUsers "users"); do
	chmod 700 "/home/users/$user"
done

for user in $(parseUsers "authors"); do
	chmod 700 "/home/authors/$user"
	chmod 755 "/home/authors/$user/public"  # public should be readable
done

# Allow admins full access
chgrp g_admin /home/users /home/authors /home/mods
chmod -R g+rwx /home/users /home/authors /home/mods

# --- 3. Mod-to-author public access ---
parseModAuthorMapping() {
	awk '
	$0 ~ "^mods_to_authors:" { in_map=1; next }
	/^[a-z]+:/ { in_map=0 }
	in_map && /mod:/ {
		mod=$2
		getline; gsub("author: ", "", $0)
		author=$0
		print mod, author
	}' "$CONFIG_FILE"
}

parseModAuthorMapping | while read -r mod author; do
	modHome="/home/mods/$mod"
	pubDir="/home/authors/$author/public"
	if [ -d "$pubDir" ]; then
		setfacl -m u:"$mod":rwX "$pubDir"
		echo "Granted $mod RW access to $author's public dir"
	fi
done

# --- 4. Create all_blogs with symlinks for users ---
mkdir -p /home/all_blogs
chown root:root /home/all_blogs
chmod 755 /home/all_blogs

for user in $(parseUsers "users"); do
	userAllBlogs="/home/users/$user/all_blogs"
	mkdir -p "$userAllBlogs"
	chown "$user:g_user" "$userAllBlogs"
	chmod 555 "$userAllBlogs"

	for author in $(parseUsers "authors"); do
		ln -sf "/home/authors/$author/public" "$userAllBlogs/$author"
	done
done
