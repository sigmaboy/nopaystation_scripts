#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.3

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "${0}")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

my_usage(){
    echo ""
    echo "Usage:"
    echo "${0} \"/path/to/DLC.tsv\" \"PCSE00986\""
}

MY_BINARIES="pkg2zip sed"
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

LIST="$(grep "^${GAME_ID}" "${TSV_FILE}"  | sed 's%.*http%http%' | tr '\n' "|" \
        | tr '\r' "%" | sed 's^%^^g')"
# both '\n' and '\r' are removed, since the TSV file is usually DOS-style
# '\r' bytes interfere with string comparison later on, so we remove them
# '\n' is replaced with a "|" character, since that's what awk will use as
# delimeter

MY_PATH="$(pwd)"

# make DESTDIR overridable
if [ -z "${DESTDIR}" ]
then
    DESTDIR="${GAME_ID}"
fi

i=1
max="$(echo "$(echo "${LIST}" | grep -o "|" | wc -l) + 1" | bc)"

while [ "${i}" -ne "${max}" ]
do
    item="$(echo "${LIST}" | awk -F "|" "{ print \$$i }")"
    i="$(echo "${i} + 1" | bc)"

    LINK="$(echo "$item" | awk '{ print $1 }')"
    KEY="$(echo "$item"  | awk '{ print $2 }')"
    LIST_SHA256="$(echo "$item" | awk '{ print $7 }')"

    if [ $KEY = "MISSING" ] || [ $LINK = "MISSING" ]
    then
        echo "zrif key or download link missing."
    else
        if [ ! -d "${MY_PATH}/${DESTDIR}_dlc" ]
        then
            mkdir "${MY_PATH}/${DESTDIR}_dlc"
        fi
        cd "${MY_PATH}/${DESTDIR}_dlc"
        my_download_file "$LINK" "${GAME_ID}_dlc.pkg"
        FILE_SHA256="$(my_sha256 "${GAME_ID}_dlc.pkg")"

        if [ "${FILE_SHA256}" != "${LIST_SHA256}" ]
        then
            echo "Checksum of downloaded file does not match checksum in list"
            echo "${FILE_SHA256} != ${LIST_SHA256}"
            yesno_checksum
        fi
        pkg2zip "${GAME_ID}_dlc.pkg" "${KEY}"
        rm "${GAME_ID}_dlc.pkg"
        cd "${MY_PATH}"
    fi
done
