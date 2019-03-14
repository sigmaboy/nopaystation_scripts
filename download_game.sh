#!/bin/bash

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.1

my_usage(){
    echo ""
    echo "Usage:"
    echo "$0 \"/path/to/GAME.tsv\" \"PCSE00986\""
}

MY_BINARIES=("curl" "pkg2zip" "sed" "sha256sum")
for bins in ${MY_BINARIES[@]}
do
    if ! which ${bins} > /dev/null 2>&1
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
if ! grep "^${GAME_ID}" ${TSV_FILE} > /dev/null
then
    echo "ERROR:"
    echo "Media ID is not found in your *.tsv file"
    echo "Check your input for a valid media ID"
    echo "Search on: \"https://renascene.com/psv/\" for"
    echo "Media IDs or simple open the *.tsv with your Office Suite."
    exit 1
fi
LIST=$(grep "^${GAME_ID}" ${TSV_FILE}| cut -f"4,5,10" | sed 's/\t/,/g')
MY_PATH=$(pwd)

LINK=$(echo $LIST | cut -d"," -f1)
KEY=$(echo $LIST | cut -d"," -f2)
LIST_SHA256=$(echo $LIST | cut -d"," -f3)

if [ $KEY = "MISSING" ] || [ $LINK = "MISSING" ]
then
    echo "zrif key missing. Cannot decrypt this package"
    exit 1
else
    wget -O ${GAME_ID}.pkg -c "$LINK"
    FILE_SHA256=$(sha256sum ${GAME_ID}.pkg | xargs | cut -d" " -f"1")
    if [ ${FILE_SHA256} != ${LIST_SHA256} ]
    then
        echo "Checksum of downloaded file does not match checksum in list"
        LOOP=1
        while [ $LOOP -eq 1 ]
        do
            echo "Do you want to continue? (yes/no)"
            read INPUT
            if [ $INPUT == "yes" ]
            then
                LOOP=0
            elif [ $INPUT == "no" ]
            then
                LOOP=0
                echo "User aborted."
                echo "Downloaded file removed."
                rm ${GAME_ID}.pkg
                exit 1
            fi
        done
    fi
    pkg2zip -l ${GAME_ID}.pkg > ${GAME_ID}.txt
    pkg2zip ${GAME_ID}.pkg "$KEY"
    rm ${GAME_ID}.pkg
fi
