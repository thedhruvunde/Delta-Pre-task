#!/bin/bash

while getopts "p:" opt; do
  case $opt in
    f)
        filename=$OPTARG
        lineNumber=1
        bWords=0
        while IFS= read -r line; do
            echo "$lineNumber: $line"
            ((lineNumber++))
        done < "$filename"
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
