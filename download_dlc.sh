#!/bin/bash

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.1

my_usage(){
    echo ""
    echo "Usage:"
    echo "$0 \"/path/to/DLC.tsv\" \"PCSE00986\""
}

MY_BINARIES=("curl" "pkg2zip")
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

LIST=$(grep "^${GAME_ID}" ${TSV_FILE} | cut -f"4,5" | sed 's/\t/,/g')
MY_PATH=$(pwd)

if [ ! -d ${MY_PATH}/${GAME_ID} ]
then
    mkdir ${MY_PATH}/${GAME_ID}
fi

for i in $LIST;
do
    LINK=$(echo $i | cut -d"," -f1)
    KEY=$(echo $i | cut -d"," -f2)
    if [ $KEY = "MISSING" ]
    then
        echo "zrif key missing. Cannot decrypt this package"
    else
        cd ${MY_PATH}/${GAME_ID}
        wget -O file.pkg -c "$LINK"
        pkg2zip file.pkg "$KEY"
        rm file.pkg
        cd ${MY_PATH}
    fi
done
