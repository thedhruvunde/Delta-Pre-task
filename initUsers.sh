#!/bin/bash



addgroup g_user
addgroup g_admin
addgroup g_mod
addgroup g_author


CONFIG_FILE="/scripts/sysad-1-users.yaml"

createUser() {
	 username=$1
	 baseDir=$2
	 userHome=${baseDir}/${username}


	 if id "$username" &>/dev/null; then	
	 	echo "User $username already exists."
	 	
	 	
	 else 
	 	useradd -m -d $userHome $username
	 	echo "Created user: $username group: $group with home: $userHome"
	 
	 fi

}



subDirs=("blogs" "public")
parseUsers(){
										
	role=$1
    group=$2
    baseDir=$3
	
	usernames=$(awk -v role="$role" '
		  $0 ~ "^" role ":" { in_role=1; next }
  		  /^[a-z]+:/ { in_role=0 }
  		  in_role && $1 ~ /username:/ {
    		  print $2}
		  ' "$CONFIG_FILE")
	
	
    	for user in $usernames; do
        	createUser "$user" "$baseDir"
        	usermod -a -G $group $user
            if [ "$group" = "g_author" ]; then
    	        for dir in "${subDirs[@]}"; do
    		        mkdir -p "/home/authors/$user/$dir"
                      echo "Author $user directories created" 
    	        done
             else
                 echo "Normal User"
            fi
    	done
}


parseUsers "admins" "g_admin" "/home/admin"
parseUsers "users" "g_user" "/home/users"
parseUsers "authors" "g_author" "/home/authors"
parseUsers "mods" "g_mod" "/home/mods"
