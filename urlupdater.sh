#!/bin/bash
## F5 Custom URL Category Update Script
## Description: provides options to add URLs, delete URLs, and list the URLs in an existing custom URL category
## Version: 2.1
## Author: Kevin Stewart
## Requires: bash, curl, jq
##
## Syntax:
##  -h     = show this help
##  -l     = list entries in the URL category
##  -a     = add an entry to the URL category
##  -d     = delete an entry from the URL category
##  -t     = replace the contents of the URL category (overwrite)
##  -f     = used with -a, -d, and -t to specify a file to read from
##  -b     = the IP address of the BIG-IP
##  -u     = username for the BIG-IP (will prompt for password)
##  
## Examples:
##  Show help:            $0 -h
##  List URLs:            $0 -b 172.16.1.84 -u admin -c test-category -l
##  Add single entry:     $0 -b 172.16.1.84 -u admin -c test-category -a https://www.foo.com/
##  Add file entries:     $0 -b 172.16.1.84 -u admin -c test-category -a file -f testfile.txt
##  Delete single entry:  $0 -b 172.16.1.84 -u admin -c test-category -d https://www.foo.com/
##  Delete file entries:  $0 -b 172.16.1.84 -u admin -c test-category -d file -f testfile.txt
##  Replace all entries:  $0 -b 172.16.1.84 -u admin -c test-category -t file -f testfile.txt
##
## URL format: supplied URLs must be in the following format:
##  https://URL/
##  
##  Example: https://www.foo.com/
##

# help print
help() {
   echo ""
   echo "Usage: $0 [options]"
   echo " -h     = show this help"
   echo " -l     = list entries in the URL category"
   echo " -a     = add an entry to the URL category"
   echo " -d     = delete aa entry from the URL category"
   echo " -t     = replace the contents of the URL category (overwrite)"
   echo " -f     = used with -a, -d, and -t to specify a file to read from"
   echo " -b     = the IP address of the BIG-IP"
   echo " -u     = username for the BIG-IP (will prompt for password)"
   echo ""
   echo "Examples:"
   echo " Show help:            $0 -h"
   echo " List URLs:            $0 -b 172.16.1.84 -u admin -c test-category -l"
   echo " Add single entry:     $0 -b 172.16.1.84 -u admin -c test-category -a https://www.foo.com/"
   echo " Add file entries:     $0 -b 172.16.1.84 -u admin -c test-category -a file -f testfile.txt"
   echo " Delete single entry:  $0 -b 172.16.1.84 -u admin -c test-category -d https://www.foo.com/"
   echo " Delete file entries:  $0 -b 172.16.1.84 -u admin -c test-category -d file -f testfile.txt"
   echo " Replace all entries:  $0 -b 172.16.1.84 -u admin -c test-category -t file -f testfile.txt"
   echo ""
   exit
}

# function to concat string array with comma separator
joinByString() {
    local separator=","
    local data="$1"
    shift
    printf "%s" "$first" "${@/#/$separator}"
}

# list category entries
list() {
    LOGIN="${USERNAME}:${PASSWORD}"
    urls=$(curl --fail -sku ${LOGIN} -H 'Content-Type: application/json' -X GET "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$CATEGORY")
    if [ -z "$urls" ]; then echo "ERROR: Request failure"; else urls=$(echo $urls |jq .urls --compact-output |sed 's/\[//g' |sed 's/\]//g'); fi
    echo "[$urls]" |jq
}

# add entries to category (supports urls in a file)
add() {
    LOGIN="${USERNAME}:${PASSWORD}"
    # get existing urls
    urls=$(curl --fail -sku ${LOGIN} -H 'Content-Type: application/json' -X GET "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$CATEGORY")
    if [ -z "$urls" ]; then echo "ERROR: Request failure"; else urls=$(echo $urls |jq .urls --compact-output |sed 's/\[//g' |sed 's/\]//g'); fi

    # test for and read from FILE, otherwise read single entry
    if [ -z "$FILE" ]
    then
        # single entry
        if [[ "$ADDENTRY" =~ .*"*".* ]]
        then
            newurl="{\"name\":\"$ADDENTRY\",\"type\":\"glob-match\"}"
        else
            newurl="{\"name\":\"$ADDENTRY\",\"type\":\"exact-match\"}"
        fi
    else
        # ignore addentry and read from FILE
        while IPS="" read -r p || [ -n "$p" ]
        do
            if [[ "$p" =~ .*"*".* ]]
            then
                myarray+=("{\"name\":\"$p\",\"type\":\"glob-match\"}")
            else
                myarray+=("{\"name\":\"$p\",\"type\":\"exact-match\"}")
            fi
        done < $FILE
        newurl=$(joinByString ${myarray[@]})
        newurl="${newurl:1}"
    fi

    # send payload to update urls
    payload="{\"urls\":[${urls},${newurl}]}"
    curl -sku ${LOGIN} -H 'Content-Type: application/json' -X PATCH "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$CATEGORY" -d ${payload} >/dev/null 2>/dev/null
}

# remove entries from category
delete() {
    LOGIN="${USERNAME}:${PASSWORD}"
    # get existing urls
    urls=$(curl --fail -sku ${LOGIN} -H 'Content-Type: application/json' -X GET "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$CATEGORY")
    if [ -z "$urls" ]; then echo "ERROR: Request failure"; else urls=$(echo $urls |jq .urls --compact-output |sed 's/\[//g' |sed 's/\]//g'); fi
    
    # test for and read from FILE, otherwise read single entry
    if [ -z "$FILE" ]
    then
        # single entry
        if [[ "$DELENTRY" =~ .*"*".* ]]
        then
            newurl="{\"name\":\"$DELENTRY\",\"type\":\"glob-match\"}"
        else
            newurl="{\"name\":\"$DELENTRY\",\"type\":\"exact-match\"}"
        fi
        modurls=`printf '%s\n' "${urls//$newurl/}"`
        payload="{\"urls\":[${modurls}]}"
        payload=`echo ${payload} |sed "s/\[,/\[/;s/,\]/\]/;s/,,/,/"`
    else
        # ignore delentry and read from FILE
        while IPS="" read -r p || [ -n "$p" ]
        do
            if [[ "$p" =~ .*"*".* ]]
            then
                newurl="{\"name\":\"$p\",\"type\":\"glob-match\"}"
            else
                newurl="{\"name\":\"$p\",\"type\":\"exact-match\"}"
            fi
            modurls=`printf '%s\n' "${urls//$newurl/}"`
            payload="{\"urls\":[${modurls}]}"
            payload=`echo ${payload} |sed "s/\[,/\[/;s/,\]/\]/;s/,,/,/"`
        done < $FILE
    fi
    curl -sku ${LOGIN} -H 'Content-Type: application/json' -X PATCH "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$CATEGORY" -d ${payload} >/dev/null 2>/dev/null
}

# replace entries from category
replace() {
    LOGIN="${USERNAME}:${PASSWORD}"
    
    # test for and read from FILE, otherwise read single entry
    if [ -z "$FILE" ]
    then
        echo "Please also specify a file with -f" && help
    else
        # read from FILE
        payload=""
        while IPS="" read -r p || [ -n "$p" ]
        do
            if [[ "$p" =~ .*"*".* ]]
            then
                newurl="{\"name\":\"$p\",\"type\":\"glob-match\"}"
            else
                newurl="{\"name\":\"$p\",\"type\":\"exact-match\"}"
            fi
            payload+="${newurl}"
        done < $FILE
        payload="{\"urls\":[${payload}]}"
        payload=`echo ${payload} |sed "s/\[,/\[/;s/,\]/\]/;s/,,/,/"`
    fi
    curl -sku ${LOGIN} -H 'Content-Type: application/json' -X PATCH "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$CATEGORY" -d ${payload} >/dev/null 2>/dev/null
}

# parse input arguments
CATEGORY=
ADDENTRY=
DELENTRY=
COMMAND=
FILE=
BIGIP=
USERNAME=
PASSWORD=
while getopts "hlc:a:f:d:t:b:u:" opt; do
    case ${opt} in
        h )
          help
          ;;
        l )
          if [ ! -z "$COMMAND" ]; then echo "Please select only one command: [-l (list) -a (add) -d (delete) -t (replace)]" && help; fi
          COMMAND=list
          ;;
        c )
          CATEGORY=$OPTARG
          ;;
        a )
          if [ ! -z "$COMMAND" ]; then echo "Please select only one command: [-l (list) -a (add) -d (delete) -t (replace)]" && help; fi
          ADDENTRY=$OPTARG
          COMMAND=add
          ;;
        d )
          if [ ! -z "$COMMAND" ]; then echo "Please select only one command: [-l (list) -a (add) -d (delete) -t (replace)]" && help; fi
          DELENTRY=$OPTARG
          COMMAND=del
          ;;
        t )
          if [ ! -z "$COMMAND" ]; then echo "Please select only one command: [-l (list) -a (add) -d (delete) -t (replace)]" && help; fi
          DELENTRY=$OPTARG
          COMMAND=rep
          ;;
        f )
          FILE=$OPTARG
          ;;
        b )
          BIGIP=$OPTARG
          ;;
        u )
          USERNAME=$OPTARG
          #PASSWORD="admin"
          echo -n Password:
          read -s PASSWORD
          #echo
          ;;
        \? )
          echo "Invalid option: $OPTARG" 1>&2
          ;;
        : )
          echo "Invalid option: $OPTARG requires an argument" 1>&2
          ;;
    esac
done

# validate arguments
if [ -z "$COMMAND" ]; then echo "ERROR: at least one command must be specified [-l (list) -a (add) -d (delete) -t (replace)]" && help; fi
if [ -z "$CATEGORY" ]; then echo "ERROR: -c CATEGORY must be specified" && help; fi
if [ -z "$BIGIP" ]; then echo "ERROR: -b BIG-IP URL must be specified" && help; fi
if [ -z "$USERNAME" ]; then echo "ERROR: -u USERNAME must be specified" && help; fi
if [ ! -z "$FILE" ] && [ ! -f "$FILE" ]; then echo "ERROR: -f FILE does not exist" && help; fi

# execute functions
if [ "$COMMAND" == "list" ]; then list; fi
if [ "$COMMAND" == "add" ]; then add; fi
if [ "$COMMAND" == "del" ]; then delete; fi
if [ "$COMMAND" == "rep" ]; then replace; fi
