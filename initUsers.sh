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


parseMods(){
										
	role=$1
    mod=$2
	
	awk -v role="$role" '
	$0 ~ "^" role ":" { in_role=1; next }
  	/^[a-z]+:/ { in_role=0 }
    $0 ~ "^" "- name" ":" { in_user=1; next }
  	/^-+[name]+[a-z]+:/ { in_user=0 }
  	in_role && $1 ~ /username:/{next}
    in_user && $2 ~ /authors:/{next}
    {print $1} ' "$CONFIG_FILE"
	   
}

parseMods() {
    yq '.mods[] | select(.username == "'"$1"'") | .authors[]' CONFIG_FILE
}
echo "Configuring mods permissions..."
parseUsers "mods" | while read -r moderator; do
    chmod 700 /home/mods/$user
    parseMods $moderator | while read -r authorname; do
        usermod -a -G $authorname $moderator
        chown $authorname:$authorname "/home/authors/$authorname"
        chmod 770 "/home/authors/$authorname"
    done
done


