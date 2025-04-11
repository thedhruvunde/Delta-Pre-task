#!/bin/bash



addgroup g_user
addgroup g_admin
addgroup g_mod
addgroup g_author


CONFIG_FILE="/scripts/sysad-1-users.yaml"

createUser() {
	 username=$1
	 group=$2
	 baseDir=$3
	 userHome="${baseDir}/${username}"


	 if id "$username" &>/dev/null; then	
	 	echo "User $username already exists."
	 	
	 	
	 else 
	 	useradd -m -d "$userHome" -g "$group" "$username"
	 	echo "Created user: $username group: $group with home: $userHome"
	 
	 fi

}



parseUsers(){
										
	role=$1
        group=$2
        baseDir=$3

    	usernames=$(grep -A 1000 "^$role:" "$CONFIG_FILE" | \
	          awk '/^ *- name:/ { getline; print $2 }' | \
		  sed '/^[a-zA-Z0-9_]*$/!d')


    	for user in $usernames; do
        	createUser "$user" "$group" "$baseDir"
    	done
}



parseUsers "admins" "g_admin" "/home/admin"
parseUsers "authors" "g_author" "/home/authors"
parseUsers "users" "g_user" "/home/users"
