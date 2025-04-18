#!/bin/bash
p_flag=""
a_flag=""
d_flag=""
e_flag=""
catl=""

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
        ;;
    d)
        d_flag=$OPTARG
        ;;
    e)
        e_flag=$OPTARG
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