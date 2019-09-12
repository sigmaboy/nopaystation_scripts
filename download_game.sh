#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.4

# return codes:
# 1 user errors
# 2 link or key missing
# 5 game archive already exists

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
source "${SCRIPT_DIR}/functions.sh"

function my_usage {
    echo ""
    echo "Usage:"
    echo "${0} \"/path/to/GAME.tsv\" \"PCSE00986\""
}

MY_BINARIES="pkg2zip sed t7z wine file"
sha256_choose; downloader_choose

check_binaries "${MY_BINARIES}"

# Get variables from script parameters
TSV_FILE="${1}"
GAME_ID="${2}"


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

# check if MEDIA ID is found in download list
if ! grep "^${GAME_ID}" "${TSV_FILE}" > /dev/null
then
    echo "ERROR:"
    echo "Media ID is not found in your *.tsv file"
    echo "Check your input for a valid media ID"
    echo "Search on: \"https://renascene.com/psv/\" for"
    echo "Media IDs or simple open the *.tsv with your Office Suite."
    exit 1
fi
LIST="$(grep "^${GAME_ID}" "${TSV_FILE}" | sed 's/.*http/http/')"

LINK="$(echo "$LIST" | awk '{ print $1 }')"
KEY="$(echo "$LIST"  | awk '{ print $2 }')"
LIST_SHA256="$(echo "$LIST" | awk '{ print $7 }')"

if [ "${KEY}" = "MISSING" ] || [ "${LINK}" = "MISSING" ]
then
    echo "zrif key or link missing. Cannot proceed."
    exit 2
else
    my_download_file "$LINK" "${GAME_ID}.pkg"
    FILE_SHA256="$(my_sha256 "${GAME_ID}.pkg")"

    if [ "${FILE_SHA256}" != "${LIST_SHA256}" ]
    then
        echo "Checksum of downloaded file does not match checksum in list"
        echo "${FILE_SHA256} != ${LIST_SHA256}"
        LOOP=1
        while [ ${LOOP} -eq 1 ]
        do
            echo "Do you want to continue? (yes/no)"
            read INPUT
            if [ "${INPUT}" == "yes" ]
            then
                LOOP=0
            elif [ "${INPUT}" == "no" ]
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
    MY_GAME_NAME="$(cat "${GAME_ID}.txt" | sed 's/\.zip//g')"
    MY_GAME_NAME="$(region_rename "${MY_GAME_NAME}")"
    if [ -f "${MY_GAME_NAME}.7z" ]
    then
        if [ "$(file -b --mime-type "${MY_GAME_NAME}.7z")" = "application/x-7z-compressed" ]
        then
            # print this to stderr
            >&2 echo "File \"${MY_GAME_NAME}.7z\" already exists."
            >&2 echo "Skip compression and remove ${GAME_ID}.pkg file"
            exit 5
        fi
    fi
    pkg2zip -x "${GAME_ID}.pkg" "${KEY}"
    rm "${GAME_ID}.pkg"
    t7z a "${MY_GAME_NAME}.7z" "app/"
    rm -rf "app/"
fi
