#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.3

# return codes:
# 1 user errors
# 2 no updates available

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

my_usage(){
    echo ""
    echo "Usage:"
    echo "${0} \"/path/to/UPDATE.tsv\" \"PCSE00986\""
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

check_valid_psv_id "${GAME_ID}"

LIST="$(grep "^${GAME_ID}" "${TSV_FILE}" | sed 's/.*http/http/' | tr '\n' "|" \
        | tr '\r' "%" | sed 's^%^^g')"

LIST=$(grep "^${GAME_ID}" "${TSV_FILE}" | cut -f"6,9" | tr '\t' '%' | tr -d '\r')
# '\r' bytes interfere with string comparison later on, so we remove them

if [ -z "${LIST}" ]
then
    echo "No updates for this game!"
    exit 2
fi

MY_PATH="$(pwd)"

# make DESTDIR overridable
if [ -z "${DESTDIR}" ]
then
    DESTDIR="${GAME_ID}"
fi

for i in ${LIST}
do
    LINK="$(echo "${i}" | cut -d"%" -f1)"
    LIST_SHA256="$(echo "${i}" | cut -d"%" -f2)"
    if [ ! -d "${MY_PATH}/${DESTDIR}_update" ]
    then
        mkdir "${MY_PATH}/${DESTDIR}_update"
    fi
    cd "${MY_PATH}/${DESTDIR}_update"
    my_download_file "$LINK" "${GAME_ID}_update.pkg"
    FILE_SHA256="$(my_sha256 "${GAME_ID}_update.pkg")"
    compare_checksum "${LIST_SHA256}" "${FILE_SHA256}"

    # get file name and modify it
    pkg2zip -l "${GAME_ID}_update.pkg" > "${GAME_ID}_update.txt"
    MY_FILE_NAME="$(cat "${GAME_ID}_update.txt" | sed 's/\.zip//g')"
    MY_FILE_NAME="$(region_rename "${MY_FILE_NAME}")"

    # extract files and compress them with t7z
    pkg2zip -x "${GAME_ID}_update.pkg"
    t7z a "${MY_FILE_NAME}.7z" "patch/"
    rm -rf "patch/"
    rm "${GAME_ID}_update.pkg"
    rm "${GAME_ID}_update.txt"
    cd "${MY_PATH}"
done
