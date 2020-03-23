#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.5

# return codes:
# 1 user errors
# 2 no updates available

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

# check for "-a" parameter
if [ "${1}" == "-a" ]
then
    ALL=1
    shift
else
    ALL=0
fi

my_usage(){
    echo ""
    echo "Usage:"
    echo "${0} \"PCSE00986\""
}

MY_BINARIES="pkg2zip sed pyNPU.py"
sha256_choose; downloader_choose

check_binaries "${MY_BINARIES}"

# Get variables from script parameters
TITLE_ID="${1}"

if [ -z "${TITLE_ID}" ]
then
    echo "No game ID found."
    my_usage
    exit 1
fi

check_valid_psv_id "${TITLE_ID}"

#LIST=$(grep "^${TITLE_ID}" "${TSV_FILE}" | cut -f"6,9" | tr '\t' '%' | tr -d '\r')
## '\r' bytes interfere with string comparison later on, so we remove them
MY_PATH="$(pwd)"

# get the download links from the pyton script
pyNPU.py --link --title-id ${TITLE_ID} > /dev/null
if [ "${?}" -eq 2 ]
then
    echo "No updates available for this game."
    exit 2
fi
# make DESTDIR overridable
if [ -z "${DESTDIR}" ]
then
    DESTDIR="${TITLE_ID}"
fi
if [ ! -d "${MY_PATH}/${DESTDIR}_update" ]
then
    mkdir "${MY_PATH}/${DESTDIR}_update"
fi

if [ "${ALL}" -eq 0 ]
then
    LIST="$(pyNPU.py --link --title-id "${TITLE_ID}")"
else
    LIST="$(pyNPU.py --link --all --title-id "${TITLE_ID}")"
fi

pyNPU.py --changelog --title-id "${TITLE_ID}" > "${MY_PATH}/${DESTDIR}_update/changelog.txt"


for i in ${LIST}
do
    cd "${MY_PATH}/${DESTDIR}_update"
    my_download_file "${i}" "${TITLE_ID}_update.pkg"
#    FIXME add support for checksums again.
#    FILE_SHA256="$(my_sha256 "${TITLE_ID}_update.pkg")"
#    compare_checksum "${LIST_SHA256}" "${FILE_SHA256}"

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
