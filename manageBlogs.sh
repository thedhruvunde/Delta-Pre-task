#!/bin/bash

AUTHOR=$(whoami)
AUTHOR_HOME="/home/authors/$AUTHOR"
BLOGS_DIR="$AUTHOR_HOME/blogs"
PUBLIC_DIR="$AUTHOR_HOME/public"
META_FILE="$AUTHOR_HOME/blogs.yaml"

CATEGORIES=("Sports" "Cinema" "Technology" "Travel" "Food" "Lifestyle" "Finance")

touch "$META_FILE"
yq e 'if .blogs then . else {blogs: []} end' -i "$META_FILE"

get_blog_index() {
    local filename=$1
    yq e ".blogs | to_entries | map(select(.value.filename == \"$filename\")) | .[0].key" "$META_FILE"
}

select_categories() {
    echo "Select categories (comma-separated index, e.g., 2,1):"
    for i in "${!CATEGORIES[@]}"; do
        echo "$i) ${CATEGORIES[$i]}"
    done
    read -p "Enter: " input
    IFS=',' read -ra ORDER <<< "$input"
    SELECTED=()
    for i in "${ORDER[@]}"; do
        SELECTED+=("\"${CATEGORIES[$i]}\"")
    done
    echo "[${SELECTED[*]}]"
}

case "$1" in
    -p)
        FILENAME="$2"
        [ ! -f "$BLOGS_DIR/$FILENAME" ] && echo "File not found in blogs/" && exit 1
        CATS=$(select_categories)
        ln -sf "$BLOGS_DIR/$FILENAME" "$PUBLIC_DIR/$FILENAME"
        chmod 644 "$PUBLIC_DIR/$FILENAME"
        IDX=$(get_blog_index "$FILENAME")
        if [[ "$IDX" == "null" ]]; then
            yq -i ".blogs += [{filename: \"$FILENAME\", status: \"published\", categories: $CATS}]" "$META_FILE"
        else
            yq -i ".blogs[$IDX].status = \"published\" | .blogs[$IDX].categories = $CATS" "$META_FILE"
        fi
        echo "[+] Published $FILENAME"
        ;;

    -a)
        FILENAME="$2"
        [ -f "$PUBLIC_DIR/$FILENAME" ] && rm "$PUBLIC_DIR/$FILENAME"
        IDX=$(get_blog_index "$FILENAME")
        [ "$IDX" != "null" ] && yq -i ".blogs[$IDX].status = \"archived\"" "$META_FILE"
        echo "[+] Archived $FILENAME"
        ;;

    -d)
        FILENAME="$2"
        rm -f "$BLOGS_DIR/$FILENAME" "$PUBLIC_DIR/$FILENAME"
        IDX=$(get_blog_index "$FILENAME")
        [ "$IDX" != "null" ] && yq -i "del(.blogs[$IDX])" "$META_FILE"
        echo "[+] Deleted $FILENAME"
        ;;

    -e)
        FILENAME="$2"
        IDX=$(get_blog_index "$FILENAME")
        [ "$IDX" == "null" ] && echo "Blog not found." && exit 1
        CATS=$(select_categories)
        yq -i ".blogs[$IDX].categories = $CATS" "$META_FILE"
        echo "[+] Updated categories for $FILENAME"
        ;;

    *)
        echo "Usage: $0 -p|-a|-d|-e <filename>"
        exit 1
        ;;
esac
