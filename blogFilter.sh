#!/bin/bash
bList="/home/mods/$USER/blacklist.txt"
while getopts "f:" opt; do
  case $opt in
    f)
        filename=$OPTARG
        lineNumber=1
        bWords=0
        cat $filename | while read -r line; do
            echo "$lineNumber: $line"
            echo $line | while read -r word; do
                cat $bList | while read -r bword; do
                    if [[$word == $bword]]; then
                        break
            ((lineNumber++))
        done
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
