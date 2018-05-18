#!/bin/bash

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.1

### usage function
my_usage(){
    echo ""
    echo "Usage:"
    echo "$0 \"PCSE00986\" \"http://announce.url\" \"/path/to/nps/directory\""
}

# check if necessary binaries are available
MY_BINARIES=("curl" "pkg2zip" "mktorrent")
for bins in ${MY_BINARIES[@]}
do
    if [ ! -x $(which ${bins}) ]
    then
        echo "$bins isn't installed."
        echo "Please install it and try again"
        exit 1
    fi
done

MEDIA_ID=${1}
ANNOUNCE_URL=${2}
NPS_DIR=${3}

### check if every parameter is set
if [ -z ${MEDIA_ID} ] || [ -z ${ANNOUNCE_URL} ] || [ -z ${NPS_DIR} ]
then
    echo "ERROR: Not every necessary option specified."
    my_usage
    exit 1
fi

### check if nps tsv file directory exists
if [ ! -d ${NPS_DIR} ]
then
    echo "Directory containing *.tsv files missing (\"${NPS_DIR}\"). Check your path parameter."
    my_usage
    exit 1
fi

### check if the tsv files are available to call download scripts
for tsv_file in PSV_GAMES.tsv PSV_DLCS.tsv PSV_UPDATES.tsv;
do
    if [ ! -f ${NPS_DIR}/${tsv_file} ]
    then
        echo "*.tsv file \"${tsv_file}\" in path \"${NPS_DIR}\" missing."
        exit 1
    fi
done

echo ${ANNOUNCE_URL} | grep "^http" &> /dev/null
if [ $? -ne 0 ]
then
    echo "No valid announce url provided. Be sure that the url starts with \"http\" and has a correct hostname"
    exit 1
fi

### Download the chosen game
download_game.sh ${NPS_DIR}/PSV_GAMES.tsv ${MEDIA_ID}

### Get name of the zip file from generated txt created via download_game.sh
ZIP_FILENAME=$(cat ${MEDIA_ID}.txt)
GAME_NAME=$(echo ${ZIP_FILENAME} | sed 's/.zip//g')

### Download available updates
DESTDIR="${GAME_NAME}" download_update.sh ${NPS_DIR}/PSV_UPDATES.tsv ${MEDIA_ID}

### Download available DLC
DESTDIR="${GAME_NAME}" download_dlc.sh ${NPS_DIR}/PSV_DLCS.tsv ${MEDIA_ID}

### Creating the torrent files
echo "Creating torrent file for \"${GAME_NAME}.zip\""
mktorrent -dpa "${ANNOUNCE_URL}" "${ZIP_FILENAME}" &> /dev/null
if [ -d "${GAME_NAME}_update" ]
then
    echo "Creating torrent file for directory \"${GAME_NAME}_update\""
    mktorrent -dpa "${ANNOUNCE_URL}" "${GAME_NAME}_update"
fi
if [ -d "${GAME_NAME}_dlc" ]
then
    echo "Creating torrent file for directory \"${GAME_NAME}_dlc\""
    mktorrent -dpa "${ANNOUNCE_URL}" "${GAME_NAME}_dlc" &> /dev/null
fi

### remove temporary game name file
rm ${MEDIA_ID}.txt

### Run post scripts
if [ -x ./create_torrent_post.sh ]
then
    ./download2torrent_post.sh ${GAME_NAME}
fi
