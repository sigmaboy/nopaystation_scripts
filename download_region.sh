#!/bin/bash

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.4

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
source "${SCRIPT_DIR}/functions.sh"

### usage function
function my_usage(){
    echo ""
    echo "Parameters:"
    echo "${0} \"REGION\" \"http://announce.url\" \"/path/to/nps/directory\" \"SOURCE_TAG\""
    echo ""
    echo "The SOURCE_TAG parameter is optional. All other parameters are required."
    echo "So if you don't want to set the source tag, just leave it off."
    echo "This is required for private torrent trackers only"
    echo ""
    echo "Valid regions:"
    echo "US JP ASIA EU"
    echo ""
    echo "Usage:"
    echo "${0} \"US\" \"http://announce.url\" \"/home/Downloads/nps\" \"GGn\""
}

function my_mktorrent(){
    local TORRENT_SOURCE="${1}"
    if [ "${SOURCE_ENABLE}" -eq 0 ]
    then
        mktorrent -l 26 -dpa "${ANNOUNCE_URL}" "${TORRENT_SOURCE}"
    else
        mktorrent -l 26 -dpa "${ANNOUNCE_URL}" -s "${SOURCE_TAG}" "${TORRENT_SOURCE}"
    fi
}

# check if necessary binaries are available
MY_BINARIES="pkg2zip mktorrent sed"
check_binaries "${MY_BINARIES}"

REGION="${1}"
ANNOUNCE_URL="${2}"
NPS_DIR="${3}"
if [ -z "${4}" ]
then
    SOURCE_ENABLE=0
else
    SOURCE_TAG="${4}"
    SOURCE_ENABLE=1
fi

if ! echo "${REGION}" | grep -E -i 'US|ASIA|EU|JP' > /dev/null
then
    echo ""
    echo "Error"
    echo "Region is not valid."
    echo "Choose from US, JP, ASIA, EU"
    echo "Check your first parameter."
    exit 1
fi

### check if every parameter is set
if [ -z "${REGION}" ] || [ -z "${ANNOUNCE_URL}" ] || [ -z "${NPS_DIR}" ]
then
    echo "ERROR: Not every necessary option specified."
    my_usage
    exit 1
fi

### check if nps tsv file directory exists
if [ ! -d "${NPS_DIR}" ]
then
    echo "Directory containing *.tsv files missing (\"${NPS_DIR}\"). Check your path parameter."
    my_usage
    exit 1
fi

### check if the tsv files are available to call download scripts
#tsv_files="PSV_GAMES.tsv PSV_DLCS.tsv PSV_UPDATES.tsv"
tsv_files="PSV_GAMES.tsv"
for tsv_file in $tsv_files
do
    if [ ! -f "${NPS_DIR}/${tsv_file}" ]
    then
        echo "*.tsv file \"${tsv_file}\" in path \"${NPS_DIR}\" missing."
        exit 1
    fi
done

echo "${ANNOUNCE_URL}" | grep "^http" &> /dev/null
if [ ${?} -ne 0 ]
then
    echo "No valid announce url provided. Be sure that the url starts with \"http\" and has a correct hostname"
    exit 1
fi

case "${REGION}" in
    "US")
        REGION_COLLECTION="NTSC"
        ;;
    "EU")
        REGION_COLLECTION="PAL"
        ;;
    "JP")
        REGION_COLLECTION="NTSC-J"
        ;;
    "ASIA")
        REGION_COLLECTION="NTSC-C"
        ;;
    *)
        echo "No valid region"
        exit 1
        ;;
esac

COLLECTION_NAME="Sony - PlayStation Vita (${REGION_COLLECTION})"

MY_PATH=$(pwd)
mkdir "${MY_PATH}/${COLLECTION_NAME}"
cd "${MY_PATH}/${COLLECTION_NAME}"

### Download every game of a specific region
for MEDIA_ID in $(grep --color -P "\t${REGION}\t" "${NPS_DIR}/${tsv_file}" | awk '{ print $1 }')
do
    echo "${MEDIA_ID}"
    download_game.sh "${NPS_DIR}/PSV_GAMES.tsv" "${MEDIA_ID}"
    if [ ${?} -ne 0 ]
    then
        echo ""
        echo "Game with the following media ID"
        echo "Cannot be downloaded."
        echo "Proceed to next game."
    fi
    ### remove temporary game name file
    rm "${MEDIA_ID}.txt"
done

#### Download available updates
#DESTDIR="${GAME_NAME}" download_update.sh "${NPS_DIR}/PSV_UPDATES.tsv" "${MEDIA_ID}"
#
#### Download available DLC
#DESTDIR="${GAME_NAME}" download_dlc.sh "${NPS_DIR}/PSV_DLCS.tsv" "${MEDIA_ID}"

cd "${MY_PATH}"

### Creating the torrent files
echo "Creating torrent file for \"${COLLECTION_NAME}\""
my_mktorrent "${COLLECTION_NAME}"


### Run post scripts
if [ -x ./download_region_post.sh ]
then
    ./download2torrent_post.sh
fi
