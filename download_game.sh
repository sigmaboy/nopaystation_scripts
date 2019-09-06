#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.1

function my_usage {
    echo ""
    echo "Usage:"
    echo "$0 \"/path/to/GAME.tsv\" \"PCSE00986\""
}

function my_sha256 {
    local file="$1"

    case "$SHA256" in
        "sha256sum")
	    sha256sum "$file" | awk '{ print $1 }' ;;
        "sha256")
	    sha256    "$file" | awk '{ print $4 }' ;;
    esac
}

function sha256_choose {
    if which > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} sha256"
	SHA256="sha256"
    else
        MY_BINARIES="${MY_BINARIES} sha256sum" 
	SHA256="sha256sum"
    fi
}

function my_download_file {
    local url="$1"
    local destination="$2"

    case "$DOWNLOADER" in
        "wget")
	    wget -O "$destination" "$url" ;;
        "curl")
	    curl -o "$destination" "$url" ;;
    esac
}

function downloader_choose {
    if which wget > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} wget"
        DOWNLOADER="wget"
    else
        MY_BINARIES="${MY_BINARIES} curl"
	DOWNLOADER="curl"
    fi
}
    
    

MY_BINARIES="pkg2zip sed"
sha256_choose; downloader_choose

for bins in $MY_BINARIES
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
LIST="$(grep "^${GAME_ID}" ${TSV_FILE}| sed 's/.*http/http/')"
MY_PATH="$(pwd)"

LINK="$(echo "$LIST" | awk '{ print $1 }')"
KEY="$(echo "$LIST"  | awk '{ print $2 }')"
LIST_SHA256="$(echo "$LIST" | awk '{ print $7 }')"

if [ "$KEY" = "MISSING" ] || [ "$LINK" = "MISSING" ]
then
    echo "zrif key missing. Cannot decrypt this package"
    exit 1
else
    my_download_file "$LINK" "${GAME_ID}.pkg"
    FILE_SHA256="$(my_sha256 "${GAME_ID}.pkg")"

    if [ "${FILE_SHA256}" != "${LIST_SHA256}" ]
    then
        echo "Checksum of downloaded file does not match checksum in list"
	echo "${FILE_SHA256} != ${LIST_SHA256}"
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
    pkg2zip -l "${GAME_ID}.pkg" > "${GAME_ID}.txt"
    pkg2zip "${GAME_ID}.pkg" "$KEY"
    rm "${GAME_ID}.pkg"
fi
