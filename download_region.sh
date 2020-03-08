#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.5

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

check_region() {
    local REGION="${1}"
    if ! echo "${REGION}" | grep -E -i 'US|ASIA|EU|JP' > /dev/null
    then
        echo ""
        echo "Error"
        echo "Region is not valid."
        echo "Choose from US, JP, ASIA, EU"
        echo "Check your region parameter."
        exit 1
    fi
}

check_type() {
    local TYPE="${1}"
    if ! echo "${TYPE}" | grep -E -i 'game|update|dlc' > /dev/null
    then
        echo ""
        echo "Error:"
        echo "Type is not valid."
        echo "Choose from game, update, dlc"
        echo "Check your type parameter."
        exit 1
    fi
}

### check if nps tsv file directory exists
test_nps_dir() {
    local NPS_DIR="${1}"
    if [ ! -d "${NPS_DIR}" ]
    then
        echo "Directory containing *.tsv files missing (\"${NPS_DIR}\"). Check your path parameter."
        my_usage
        exit 1
    fi
}

### usage function
my_usage(){
    echo ""
    echo "Parameters:"
    echo "--region|-r <REGION>             valid regions: US JP ASIA EU"
    echo "--nps-dir|-d <DIR>               path to the directory containing the tsv files"
    echo "--type|-t <TYPE>                 valid types: game update dlc"
    echo "--torrent|-c <ANNOUNCE URL>      Enables torrent creation. Needs announce url"
    echo "--source|-s <SOURCE TAG>         Enables source flag. Needs source tag as argument"
    echo ""
    echo "The \"--source\" and \"--torrent\" parameter are optional. All other"
    echo "parameters are required. The source parameter"
    echo "is required for private torrent trackers only"
    echo ""
    echo "Usage:"
    echo "${0} --region <REGION> --type Game --nps-dir </path/to/nps/directory> [--torrent \"http://announce.url\"] [--source <SOURCE_TAG>]"
}

# setting variable defaults
SOURCE_ENABLE=0
CREATE_TORRENT=0

while [ ${#} -ge 1 ]
do
    opt=${1}
    shift
    case ${opt} in
        -c|--torrent)
            test -n "${1}"
            exit_if_fail "\"-c\" used without torrent announce URL"
            check_announce_url "${1}"
            ANNOUNCE_URL="${1}"
            CREATE_TORRENT=1
            shift
            ;;
        -s|--source)
            test -n "${1}"
            exit_if_fail "\"-s\" used without source flag argument used"
            SOURCE_TAG="${1}"
            SOURCE_ENABLE=1
            shift
            ;;
        -d|--nps-dir)
            test -n "${1}"
            exit_if_fail "\"-d\" used without directory path argument used"
            test_nps_dir "${1}"
            NPS_DIR="${1}"
            shift
            ;;
        -r|--region)
            test -n "${1}"
            exit_if_fail "\"-r\" used without region argument used"
            check_region "${1}"
            REGION="${1}"
            shift
            ;;
        -t|--type)
            test -n "${1}"
            exit_if_fail "\"-t\" used without type argument used"
            check_type "${1}"
            TYPE="${1}"
            shift
            ;;
        *)
            echo "Invalid parameter used."
            my_usage
            echo ""
            exit 1
            ;;
    esac
done

my_mktorrent(){
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

### check if every parameter is set
if [ -z "${REGION}" ] || [ -z "${NPS_DIR}" ] || [ -z "${TYPE}" ]
then
    echo "ERROR: Not every necessary option specified."
    my_usage
    exit 1
fi

NPS_ABSOLUTE_PATH="$(readlink -f "${NPS_DIR}")"

# choose fitting TSV file
case "${TYPE}" in
    "game")
        tsv_file="PSV_GAMES.tsv"
        ;;
    "update")
        tsv_file="PSV_UPDATES.tsv"
        echo 'At the moment only the "game" type is supported'
        echo 'Sorry'
        exit 1
        ;;
    "dlc")
        tsv_file="PSV_DLCS.tsv"
        echo 'At the moment only the "game" type is supported'
        echo 'Sorry'
        exit 1
        ;;
esac

### check if the tsv file is available to call download scripts
if [ ! -e "${NPS_ABSOLUTE_PATH}/${tsv_file}" ]
then
    echo "*.tsv file \"${tsv_file}\" in path \"${NPS_DIR}\" missing."
    exit 1
fi

COLLECTION_NAME="Sony - PlayStation Vita (${REGION_COLLECTION})"

MY_PATH=$(pwd)
test ! -d "${MY_PATH}/${COLLECTION_NAME}" && mkdir "${MY_PATH}/${COLLECTION_NAME}"
cd "${MY_PATH}/${COLLECTION_NAME}"

### Download every game of a specific region
# yeah this grep pattern is really ugly but only gnu grep allows "grep -P" to search for tabs without modifications
for MEDIA_ID in $(grep $'\t'"${REGION}"$'\t' "${NPS_ABSOLUTE_PATH}/${tsv_file}" | awk '{ print $1 }')
do
    echo "Downloading and packing \"${MEDIA_ID}\"..."
    download_game.sh "${NPS_ABSOLUTE_PATH}/PSV_GAMES.tsv" "${MEDIA_ID}"
    case ${?} in
        2)
        echo ""
        echo "Key or link not available for \"${MEDIA_ID}\"."
        echo "Proceed to next game."
        ;;
        3)
        echo ""
        echo "Game \"${MEDIA_ID}\" is physical only."
        echo "Proceed to next game."
        ;;
        5)
        echo ""
        echo "A t7z archive for the game \"${MEDIA_ID}\""
        echo "is already present."
        echo "Proceed to next game."
        ;;
        0)
        echo ""
        echo "Game \"${MEDIA_ID}\" successfully downloaded"
        echo "and compressed."
        echo "Proceed to next game."
        ;;
        *)
        echo ""
        echo "Game with the following media ID"
        echo "cannot be downloaded."
        echo "Proceed to next game."
        ;;
    esac
    ### remove temporary game name file
    rm "${MEDIA_ID}.txt"
done

#### Download available updates
#DESTDIR="${GAME_NAME}" download_update.sh "${NPS_ABSOLUTE_PATH}/PSV_UPDATES.tsv" "${MEDIA_ID}"
#
#### Download available DLC
#DESTDIR="${GAME_NAME}" download_dlc.sh "${NPS_ABSOLUTE_PATH}/PSV_DLCS.tsv" "${MEDIA_ID}"

cd "${MY_PATH}"

### Creating the torrent files if set
if [ ${CREATE_TORRENT} -eq 1 ]
then
    echo "Creating torrent file for \"${COLLECTION_NAME}\""
    my_mktorrent "${COLLECTION_NAME}"
fi


### Run post scripts
if [ -x ./download_region_post.sh ]
then
    ./download_region_post.sh
fi
