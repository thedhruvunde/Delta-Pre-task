#!/bin/bash

AUTHOR=$(whoami)
AUTHOR_HOME="/home/authors/$AUTHOR"
BLOGS_DIR="$AUTHOR_HOME/blogs"
PUBLIC_DIR="$AUTHOR_HOME/public"
META_FILE="$AUTHOR_HOME/blogs.yaml"

p_flag=""
a_flag=""
d_flag=""
e_flag=""
CATS=""

get_categories() {
    yq '.categories[]' "$META_FILE" | sort -u
}

while getopts "p:a:d:e:" opt; do
  case $opt in
    p)
        p_flag=$OPTARG
        echo "Enter Categories for the blog: "
        read CATS

        if [ ! -f "$BLOGS_DIR/$p_flag" ]; then
        echo "Error: Blog file '$p_flag' does not exist in $BLOGS_DIR."
        exit 1
        fi

        yq -i ".blogs += [{\"file_name\": \"$p_flag\", \"publish_status\": true, \"cat_order\": \"$CATS\"}]" "$META_FILE"
        ln -s "$BLOGS_DIR/$p_flag" "$PUBLIC_DIR/$p_flag"
        chmod o+r "$BLOGS_DIR/$p_flag"
        ;;
    a)
        a_flag=$OPTARG
        echo "Archiving blog..."
        rm "$PUBLIC_DIR/$a_flag"
        bindex=$(yq ".blogs | to_entries | map(select(.value.file_name == \"$a_flag\")) | .[0].key" "$META_FILE")
        yq -i '.blogs[$bindex].publish_status = false' "$META_FILE"
        chmod o-r "$BLOGS_DIR/$a_flag"

        ;;
    d)
        d_flag=$OPTARG
        echo "Deleting blog..."
        rm -f "$PUBLIC_DIR/$d_flag"
        rm -f "$BLOGS_DIR/$d_flag"
        bindex=$(yq ".blogs | to_entries | map(select(.value.file_name == \"$d_flag\")) | .[0].key" "$META_FILE")
        yq -i 'del(.blogs[$bindex])' "$META_FILE"
        ;;
    e)
        e_flag=$OPTARG
        echo "Enter the order of categories"
        i=1
        get_categories | while read -r category; do
            echo "$i -> $category"
            ((i++))
        done
        read cats
        bindex=$(yq ".blogs | to_entries | map(select(.value.file_name == \"$e_flag\")) | .[0].key" "$META_FILE")
        yq -i ".blogs[$bindex].cat_order = \"$cats\"" "$META_FILE"
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done
