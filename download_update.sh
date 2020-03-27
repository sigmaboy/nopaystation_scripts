#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>

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

MY_BINARIES="pkg2zip sed python3 pyNPU.py"
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
    echo "No updates available for this game."
    exit 2
fi

# make DESTDIR overridable
if [ -z "${DESTDIR}" ]
then
    DESTDIR="${TITLE_ID}"
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
    if find . -depth 1 -type f -name "*[${TITLE_ID}]*.7z" | grep -E "\[${TITLE_ID}\].*\.7z"
    then
        COUNT=0
        for FOUND_FILE in $(find . -depth 1 -type f -name "*[${TITLE_ID}]*[PATCH]*.7z" | grep -E "\[${TITLE_ID}\].*\[PATCH\].*\.7z" | sed 's@./@@g')
        if [ "$(file -b --mime-type "${FOUND_FILE}")" = "application/x-7z-compressed" ]
        then
            COUNT=$((${COUNT} + 1))
            # print this to stderr
            >&2 echo "File \"${FOUND_FILE}\" already exists."
        else
            COUNT=$((${COUNT} + 1))
            # print this to stderr
            >&2 echo "File \"${FOUND_FILE}.7z\" already exists."
            >&2 echo "But it doesn't seem to be a valid 7z file"
        fi
        >&2 echo ""
        >&2 echo "${COUNT} updates already present"
        cd "${MY_PATH}"
        exit 5
    else
        my_download_file "${i}" "${TITLE_ID}_update.pkg"

        pkg2zip -l "${TITLE_ID}_update.pkg" > "${TITLE_ID}_update.txt"
        MY_FILE_NAME="$(cat "${TITLE_ID}_update.txt" | sed 's/\.zip//g')"
        MY_FILE_NAME="$(region_rename "${MY_FILE_NAME}")"

        # extract files and compress them with t7z
        test -d "patch/" && rm -rf "patch/"
        pkg2zip -x "${TITLE_ID}_update.pkg"
        t7z a "${MY_FILE_NAME}.7z" "patch/"
        rm -rf "patch/"
        rm "${TITLE_ID}_update.pkg"
        rm "${TITLE_ID}_update.txt"
        cd "${MY_PATH}"
    fi
done
