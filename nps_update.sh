#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>

# return codes:
# 1 user errors
# 2 no updates available
# 5 game archives already exist

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

MY_BINARIES="pkg2zip sed grep file python3 pyNPU.py"
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

# get current working directory
MY_PATH="$(pwd)"


# test if any update is available
pyNPU.py --link --title-id ${TITLE_ID} > /dev/null
if [ "${?}" -eq 2 ]
then
    >&2 echo "No updates available for title ID \"${TITLE_ID}\"."
    exit 2
fi

GAME_NAME="$(pyNPU.py --name --title-id "${TITLE_ID}")"

# make DESTDIR overridable
if [ -z "${DESTDIR}" ]
then
    RENAME=1
    DESTDIR="${TITLE_ID}"
else
    RENAME=0
fi

# create download dir if updates for this game are available
if [ ! -d "${MY_PATH}/${DESTDIR}_update" ]
then
    mkdir "${MY_PATH}/${DESTDIR}_update"
fi

# get the download links from the pyton script
# check if the script should just output the latest update or all
if [ "${ALL}" -eq 0 ]
then
    LIST="$(pyNPU.py --link --title-id "${TITLE_ID}")"
else
    LIST="$(pyNPU.py --link --all --title-id "${TITLE_ID}")"
fi

# download changelog in *.txt format
pyNPU.py --changelog --title-id "${TITLE_ID}" > "${MY_PATH}/${DESTDIR}_update/changelog.txt"

for i in ${LIST}
do
    cd "${MY_PATH}/${DESTDIR}_update"
    if find . -maxdepth 1 -type f -name "*[${TITLE_ID}]*.${ext}" | grep -q -E "\[${TITLE_ID}\].*\.${ext}"
    then
        COUNT=0
        for FOUND_FILE in "$(find . -maxdepth 1 -type f -name "*[${TITLE_ID}]*[PATCH]*.${ext}" | grep -E "\[${TITLE_ID}\].*\[PATCH\].*\.${ext}" | sed 's@\./@@g')"
        do
            if [ "$(file -b --mime-type "${FOUND_FILE}")" = "${mime_type}" ]
            then
                COUNT=$((${COUNT} + 1))
                # print this to stderr
                >&2 echo "File \"${FOUND_FILE}\" already exists."
            else
                COUNT=$((${COUNT} + 1))
                # print this to stderr
                >&2 echo "File \"${FOUND_FILE}\" already exists."
                >&2 echo "But it doesn't seem to be a valid ${ext} file"
            fi
        done
        >&2 echo ""
        >&2 echo "${COUNT} updates already present"
        cd "${MY_PATH}"
        exit 5
    else
        my_download_file "${i}" "${TITLE_ID}_update.pkg"
        pkg2zip "${TITLE_ID}_update.pkg"
        rm "${TITLE_ID}_update.pkg"
        cd "${MY_PATH}"
    fi
done

if [ ${RENAME} -eq 1 ]
then
    # this code is pretty ugly. It's just to make sure the directory naming scheme behaves like when overriding $DESTDIR with the game name
    REGION_NAME="$(basename "$(find "${MY_PATH}/${DESTDIR}_update" -type f -name "*.${ext}" | head -n 1)" | sed "s/.*\[${TITLE_ID}\] \[//g" | sed 's/\] \[PATCH.*//')"
    mv "${MY_PATH}/${DESTDIR}_update" "${MY_PATH}/${GAME_NAME} [${TITLE_ID}] [${REGION_NAME}]_update"
fi
