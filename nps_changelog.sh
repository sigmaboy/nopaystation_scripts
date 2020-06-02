#!/bin/sh

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

my_usage() {
    echo ""
    echo "Usage:"
    echo "${0} \"/path/to/GAME.tsv\" \"PCSE00986\""
}

MY_BINARIES="pkg2zip sed"
sha256_choose; downloader_choose

check_binaries "${MY_BINARIES}"

TITLE_ID="${1}"

check_valid_psv_id "${TITLE_ID}"

pyNPU.py -ct "${TITLE_ID}" > /dev/null
if [ ${?} -eq 2 ]
then
    echo "No game update found."
    exit 2
fi
pyNPU.py -ct "${TITLE_ID}" > "${TITLE_ID}_changelog.txt"

