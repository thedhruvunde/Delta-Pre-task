#!/bin/bash
p_flag=""
a_flag=""
d_flag=""
e_flag=""
catl=""
BLOG_CONFIG="/scripts/blogs.yaml"

get_categories() {
    yq "[].categories" "$BLOG_CONFIG" | sort -u
}
while getopts "p:a:d:e:" opt; do
  case $opt in
    p)
        p_flag=$OPTARG
        echo "Enter Categories in which the blog belong: "
        read catl
        echo catl
        ln -s "$p_flag" "~/public/$p_flag"
        ;;
    a)
        a_flag=$OPTARG
        echo "Archiving blog..."
        rm "~/public/$a_flag"
        ;;
    d)
        d_flag=$OPTARG
        echo "Deleting blog..."
        rm "~/public/$d_flag"
        rm "~/blogs/$d_flag"
        ;;
    e)
        e_flag=$OPTARG
        echo "Enter the order of categories"
        i=1
        get_categories | while read -r category; do
            echo "$i -> $category"
            i=i+1
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
