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


parseUsers "admins" | while read -r user; do
	HomeDir=/home/admin/$user
	createUser "$user" "$HomeDir" "g_admin" "admin"
done


parseUsers "users" | while read -r user; do
	HomeDir=/home/users/$user
	createUser "$user" "$HomeDir" "g_user" "users"
done


parseUsers "authors" | while read -r user; do
	HomeDir=/home/authors/$user
	createUser "$user" "$HomeDir" "g_author" "author"
	
	subDirs=("blogs" "public")
	for dir in "${subDirs[@]}"; do
        	mkdir -p "/home/authors/$user/$dir"
        	echo "Author $user directories created" 
	done
done



parseUsers "mods" | while read -r user; do
	HomeDir=/home/mods/$user
	createUser "$user" "$HomeDir" "g_mod" "mods"
done


