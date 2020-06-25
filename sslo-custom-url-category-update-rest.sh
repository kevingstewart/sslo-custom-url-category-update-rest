#!/bin/bash
## F5 Custom URL Category Update Script
## Description: provides options to add URLs, delete URLs, and list the URLs in an existing custom URL category
## Version: 1.0
## Requires: bash, curl, jq
## To-do: add BIGIP and LOGIN variables as command input
##
## Syntax:
##      To Add URLs:
##      Command:    script.sh add <category> <URL> <[exact-match|glob-match]>
##      Examples:   script.sh add MY_CATEGORY https://www.example.com/ exact-match
##                  script.sh add MY_CATEGORY https://*.foo.com/ glob-match
##
##      To List URLs:
##      Command:    script.sh list <category>
##      Example:    script.sh list MY_CATEGORY
##
##      To Delete URLs:
##      Command:    script.sh del <category> <URL> <[exact-match|glob-match]>
##      Examples:   script.sh del MY_CATEGORY https://www.example.com/ exact-match
##                  script.sh del MY_CATEGORY https://*.foo.com/ glob-match
##

BIGIP="172.16.1.70"
LOGIN='admin:admin'

## Display command usage
display_usage () {
    echo "Custom URL Category Update Script"
    echo ""
    echo "   To add URLs to a custom category:"
    echo "   script.sh add <category> <URL> <[exact-match|glob-match]>"
    echo ""
    echo "   To list URLs in a custom category:"
    echo "   script.sh list <category>"
    echo ""
    echo "   To remove URLs from a custom category:"
    echo "   script del <category> <URL> <[exact-match|glob-match]>"
    echo ""
    exit 1
}

## Add URLs
add_urls () {
    if [[ -z "$1" || -z "$2" || -z "$3" ]]
    then
        display_usage
    fi

    ## Get current URLs
    urls=`curl -sku ${LOGIN} -H 'Content-Type: application/json' -X GET "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$1" |jq .urls --compact-output |sed 's/\[//g' |sed 's/\]//g'`

    if [ "$3" == "exact-match" ]
    then
        newurl="{\"name\":\"$2\",\"type\":\"exact-match\"}"
    elif [ "$3" == "glob-match" ]
    then
        newurl="{\"name\":\"$2\",\"type\":\"glob-match\"}"
    else
        display_usage
    fi

    ## Update category
    payload="{\"urls\":[${urls},${newurl}]}"
    curl -sku ${LOGIN} -H 'Content-Type: application/json' -X PATCH "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$1" -d ${payload} |jq
}

## List URLs
list_urls () {
    if [[ -z "$1" ]]
    then
        display_usage
    fi

    ## Get current URLs
    urls=`curl -sku ${LOGIN} -H 'Content-Type: application/json' -X GET "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$1" |jq .urls --compact-output |sed 's/\[//g' |sed 's/\]//g'`
    echo $urls
}

## Delete URLs
del_urls () {
    if [[ -z "$1" || -z "$2" || -z "$3" ]]
    then
        display_usage
    fi

    ## Get current URLs
    urls=`curl -sku ${LOGIN} -H 'Content-Type: application/json' -X GET "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$1" |jq .urls --compact-output |sed 's/\[//g' |sed 's/\]//g'`

    if [ "$3" == "exact-match" ]
    then
        newurl="{\"name\":\"$2\",\"type\":\"exact-match\"}"
    elif [ "$3" == "glob-match" ]
    then
        newurl="{\"name\":\"$2\",\"type\":\"glob-match\"}"
    else
        display_usage
    fi

    ## Update category
    modurls=`printf '%s\n' "${urls//$newurl/}"`
    payload="{\"urls\":[${modurls}]}"
    payload=`echo ${payload} |sed "s/\[,/\[/;s/,\]/\]/;s/,,/,/"`    
    curl -sku ${LOGIN} -H 'Content-Type: application/json' -X PATCH "https://${BIGIP}/mgmt/tm/sys/url-db/url-category/$1" -d ${payload} |jq
}

## Test for command inputs
if [[ "$1" == "add" ]]
then
    add_urls $2 $3 $4
elif [[ "$1" == "list" ]]
then
    list_urls $2
elif [[ "$1" == "del" ]]
then
    del_urls $2 $3 $4
else
    display_usage
fi
exit 1
