#!/bin/bash

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.1

my_usage(){
    echo ""
    echo "Usage:"
    echo "$0 \"/path/to/GAME.tsv\" \"PCSE00986\""
}

MY_BINARIES=("curl" "pkg2zip" "sed")
for bins in ${MY_BINARIES[@]}
do
    if [ ! -x $(which ${bins}) ]
    then
        echo "$bins isn't installed."
        echo "Please install it and try again"
        exit 1
    fi
done

# Get variables from script parameters
TSV_FILE=$1
GAME_ID=$2


if [ ! -f $TSV_FILE ]
then
    echo "No TSV file found."
    my_usage
    exit 1
fi
if [ -z ${GAME_ID} ]
then
    echo "No game ID found."
    my_usage
    exit 1
fi

# check if MEDIA ID is found in download list
if ! grep "^${GAME_ID}" ${TSV_FILE}
then
    echo "ERROR:"
    echo "Media ID is not found in your *.tsv file"
    echo "Check your input for a valid media ID"
    echo "Search on: \"https://renascene.com/psv/\" for"
    echo "Media IDs or simple open the *.tsv with your Office Suite."
    exit 1
fi
LIST=$(grep "^${GAME_ID}" ${TSV_FILE}| cut -f"4,5" | sed 's/\t/,/g')
MY_PATH=$(pwd)

LINK=$(echo $LIST | cut -d"," -f1)
KEY=$(echo $LIST | cut -d"," -f2)
if [ $KEY = "MISSING" ] || [ $LINK = "MISSING" ]
then
    echo "zrif key missing. Cannot decrypt this package"
    exit 1
else
    wget -O ${GAME_ID}.pkg -c "$LINK"
    pkg2zip -l ${GAME_ID}.pkg > ${GAME_ID}.txt
    pkg2zip ${GAME_ID}.pkg "$KEY"
    rm ${GAME_ID}.pkg
fi
