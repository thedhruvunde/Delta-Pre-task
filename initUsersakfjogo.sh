#!/bin/bash

apt update && apt install wget -y
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq


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
	 	useradd -m -d $userHome $username
        usermod -a -G $group $username
	 	echo "Created user: $username group: $group with home: $userHome" 
	 fi

}



parseUsers(){
										
	role=$1
	
	awk -v role="$role" '
	$0 ~ "^" role ":" { in_role=1; next }
  	/^[a-z]+:/ { in_role=0 }
  	in_role && $1 ~ /username:/ {
    print $2} ' "$CONFIG_FILE"
	
           
}

echo "Processing admins..."
parseUsers "admins" | while read -r user; do
	HomeDir=/home/admin/$user
	createUser "$user" "$HomeDir" "g_admin" "admin"
done

echo "Processing users..."
parseUsers "users" | while read -r user; do
	HomeDir=/home/users/$user
	createUser "$user" "$HomeDir" "g_user" "users"
done

echo "Processing authors..."
parseUsers "authors" | while read -r user; do
	HomeDir=/home/authors/$user
	createUser "$user" "$HomeDir" "g_author" "author"
	
	subDirs=("blogs" "public")
	for dir in "${subDirs[@]}"; do
        	mkdir -p "/home/authors/$user/$dir"
        	echo "Author $user directories created" 
	done
done


echo "Processing mods..."
parseUsers "mods" | while read -r user; do
	HomeDir=/home/mods/$user
	createUser "$user" "$HomeDir" "g_mod" "mods"
done


echo "Configuring user permissions..."
parseUsers "users" | while read -r user; do
    chmod 700 /home/users/$user
done

echo "Configuring admin permissions..."
parseUsers "admins" | while read -r user; do
    chmod 700 /home/admin/$user
    usermod -a -G sudo $user
done


parseMods() {
    yq '.mods[] | select(.username == "'"$1"'") | .authors[]' CONFIG_FILE
}
echo "Configuring mods permissions..."
parseUsers "mods" | while read -r moderator; do
    chmod 700 /home/mods/$user
    parseMods $moderator | while read -r authorname; do
        usermod -a -G $authorname $moderator
        chown $authorname:$authorname "/home/authors/$authorname/public"
        chmod 770 "/home/authors/$authorname"
    done
done



echo "Creating all_blogs symlinks for users..."
authors=$(yq '.authors[].username' "$CONFIG_FILE")

parseUsers "users" | while read -r user; do
    allBlogsDir="/home/users/$user/all_blogs"
    mkdir -p "$allBlogsDir"

    for author in $authors; do
        target="/home/authors/$author/public"
        linkname="$allBlogsDir/$author"
        ln -s "$target" "$linkname"
    done

    chmod 500 "$allBlogsDir"
    chmod -R 500 "$allBlogsDir"/*
    echo "All blog links created for user: $user"
done



getExistingUsersInGroup() {
    getent group "$1" | awk -F: '{print $4}' | tr ',' '\n' | sort | uniq
}

getYamlUsersByRole() {
    yq ".${1}[].username" "$CONFIG_FILE" | sort | uniq
}

syncUsersInGroup() {
    local role=$1
    local group=$2

    existingUsers=$(getExistingUsersInGroup "$group")
    yamlUsers=$(getYamlUsersByRole "$role")

    for user in $existingUsers; do
        if ! grep -qx "$user" <<< "$yamlUsers"; then
            echo "Revoking $role access from removed user: $user"
            gpasswd -d "$user" "$group" 2>/dev/null
        fi
    done
}

syncUsersInGroup "users" "g_user"
syncUsersInGroup "authors" "g_author"
syncUsersInGroup "mods" "g_mod"
syncUsersInGroup "admins" "g_admin"

echo "Updating moderators' author access..."

parseUsers "mods" | while read -r mod; do
    echo "Resetting author groups for moderator: $mod"

    # Remove mod from all current author groups
    for author in $(getYamlUsersByRole "authors"); do
        gpasswd -d "$mod" "$author" 2>/dev/null
    done

    # Re-add based on YAML
    yq '.mods[] | select(.username == "'"$mod"'") | .authors[]' "$CONFIG_FILE" | while read -r authorname; do
        echo "Granting $mod access to $authorname"
        usermod -a -G "$authorname" "$mod"
        chown "$authorname:$authorname" "/home/authors/$authorname/public"
        chmod 770 "/home/authors/$authorname"
    done
done

echo "Granting admin users full access to all directories..."

parseUsers "admins" | while read -r admin; do
    for dir in /home/users/* /home/authors/* /home/mods/*; do
        [ -d "$dir" ] && setfacl -m u:$admin:rwx "$dir"
    done
done
