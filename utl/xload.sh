#!/bin/bash

#
# Purpose:  Utility script to generate fixed load for an API/microservice.
#
# Paameters:
#   $1:  max interval between messages (average interval is half of this)
#
# Author: Eric Broda, ericbroda@rogers.com
#

function showHelp {
    echo " "
    echo "Error: $1"
    echo " "
    echo "    xload.sh [uri] [interval] [num-requests] [bearer-token]"
    echo " "
    echo "    where [uri] is the url of the api (required)"
    echo "          [interval] interval in seconds between messages (required)"
    echo "          [num-requests] is the number of requests to generate before exiting"
    echo "          [bearer-token] is the bearer token received from the OAUTH provider (optional, only needed if secure requests are to be issued)"
    echo " "
    echo "    example 1: Generate load for an API"
    echo "               xload.sh http://localhost:7010/v1/myaccounts/1 2 10"
    echo "               where the fully qualified uri is: http://localhost:7010/v1/myaccounts/1 "
    echo "               and   the interval is: 2 (seconds) "
    echo "               and   the number of requests is 10"
    echo " "
    echo "    example 2: Generate load for a secure API"
    echo "               xload.sh http://localhost:7010/v1/myaccounts/1 2 10 \$xBEARERTOKEN "
    echo "               where the fully qualified uri is: http://localhost:7010/v1/myaccounts/1 "
    echo "               and   the interval is: 2 (seconds) "
    echo "               and   the number of requests is 10"
    echo "               and   \$xBEARERTOKEN is an environment variable containing the bearer token"
    echo " "
}

if [ -z $1 ]; then
    showHelp "[uri] parameter is missing"
    exit
fi
xFQURI=$1

if [ -z $2 ]; then
    showHelp "[interval] parameter is missing"
    exit
fi
export xINTERVAL=$2

if [ -z $3 ]; then
    showHelp "[num-requests] parameter is missing"
    exit
fi
export xNUMREQUESTS=$3

export xBEARERTOKEN=$4
if [ -z $4 ]; then
    unset xBEARERTOKEN
fi


xAVGRPS=$(bc <<<"scale=2;1/$xINTERVAL")

echo "--- Executing loader ---"
echo "Interval:      $xINTERVAL seconds"
echo "Estimated RPS: $xAVGRPS requests per second"
echo "Num Requests:  $xNUMREQUESTS"
echo "Bearer Token:"
echo "$xBEARERTOKEN"

xCOUNTER=0
while [  $xCOUNTER -lt $xNUMREQUESTS ]; do
    let xCOUNTER=xCOUNTER+1

    xTIMESTAMP=`date +%Y-%m-%d:%H:%M:%S`
    echo " "
    echo "--- REQUEST #$xCOUNTER, URI: $xURI at: $xTIMESTAMP ---"
    echo "--- RESPONSE (START)---"

    if [ "$xBEARERTOKEN" == "" ]; then
        ./xcurl.sh $xFQURI
    else
        ./xcurl-secure.sh $xFQURI $xBEARERTOKEN
    fi

    echo " "
    echo "--- RESPONSE (FINISH)---"

    echo "Sleeping: $xINTERVAL seconds"
    sleep $xINTERVAL
done
