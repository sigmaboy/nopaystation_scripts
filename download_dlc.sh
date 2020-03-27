#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>

# return codes:
# 1 user errors
# 2 no DLC available
# 4 no key or link available
# 5 game archive already exists

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

check_valid_psv_id "${GAME_ID}"
MY_PATH="$(pwd)"

# make DESTDIR overridable
if [ -z "${DESTDIR}" ]
then
    DESTDIR="${GAME_ID}"
fi

if ! grep -q "^${GAME_ID}" "${TSV_FILE}"
then
    exit 2
fi

LIST=$(grep "^${GAME_ID}" "${TSV_FILE}" | cut -f"4,5,9" | tr '\t' '%' | tr -d '\r')
# '\r' bytes interfere with string comparison later on, so we remove them

for i in ${LIST}
do
    LINK=$(echo "${i}" | cut -d"%" -f1)
    KEY=$(echo "${i}" | cut -d"%" -f2)
    LIST_SHA256=$(echo "${i}" | xargs | cut -d"%" -f3)

    if [ "${LINK}" = "MISSING" ] && [ "${KEY}" = "MISSING" ]
    then
        echo "Download link and zRIF key are missing."
        exit 4
    elif [ "${LINK}" = "MISSING" ]
    then
        echo "Download link is missing."
        exit 4
    elif [ "${KEY}" = "MISSING" ]
    then
        echo "zRIF key is missing."
        exit 4
    else
        if [ ! -d "${MY_PATH}/${DESTDIR}_dlc" ]
        then
            mkdir "${MY_PATH}/${DESTDIR}_dlc"
        fi
        cd "${MY_PATH}/${DESTDIR}_dlc"

        if find . -depth 1 -type f -name "*[${TITLE_ID}]*[DLC*.7z" | grep -E "\[${TITLE_ID}\].*\[DLC.*\.7z"
        then
            COUNT=0
            for FOUND_FILE in $(find . -depth 1 -type f -name "*[${TITLE_ID}]*[DLC*.7z" | grep -E "\[${TITLE_ID}\].*\[DLC.*\.7z" | sed 's@./@@g')
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
            >&2 echo "${COUNT} DLC(s) already present"
            cd "${MY_PATH}"
            exit 5
        else
            my_download_file "${LINK}" "${GAME_ID}_dlc.pkg"
            FILE_SHA256="$(my_sha256 "${GAME_ID}_dlc.pkg")"
    
            compare_checksum "${LIST_SHA256}" "${FILE_SHA256}"
            pkg2zip "${GAME_ID}_dlc.pkg" "${KEY}"
            rm "${GAME_ID}_dlc.pkg"
            cd "${MY_PATH}"
        fi
    fi
done
