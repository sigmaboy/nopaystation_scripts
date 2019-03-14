#!/bin/bash

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.1

my_usage(){
    echo ""
    echo "Usage:"
    echo "$0 \"/path/to/DLC.tsv\" \"PCSE00986\""
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

if [ ! -f "${TSV_FILE}" ]
then
    echo "No TSV file found."
    my_usage
    exit 1
fi
if [ -z "${GAME_ID}" ]
then
    echo "No game ID found."
    my_usage
    exit 1
fi

LIST=$(grep "^${GAME_ID}" "${TSV_FILE}" | cut -f"6,10" | sed 's/\t/,/g' | sed 's/\r//g')
MY_PATH=$(pwd)

# make DESTDIR overridable
if [ -z "$DESTDIR" ]
then
    DESTDIR="${GAME_ID}"
fi

for i in $LIST;
do
    LINK=$(echo $i | cut -d"," -f1)
    LIST_SHA256=$(echo $i | xargs | cut -d"," -f2)
    if [ ! -d "${MY_PATH}/${DESTDIR}_update" ]
    then
        mkdir "${MY_PATH}/${DESTDIR}_update"
    fi
    cd "${MY_PATH}/${DESTDIR}_update"
    wget -O ${GAME_ID}_update.pkg -c "$LINK"
    FILE_SHA256=$(sha256sum ${GAME_ID}_update.pkg | xargs | cut -d" " -f"1")
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
                rm ${GAME_ID}_update.pkg
                exit 1
            fi
        done
    fi
    pkg2zip ${GAME_ID}_update.pkg
    rm ${GAME_ID}_update.pkg
    cd ${MY_PATH}
done
