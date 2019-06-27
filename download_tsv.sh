#!/bin/sh
HEADER="https://"
BASE_URL="nopaystation.com"
MY_URL_PATH="tsv"
LIST="PSV_GAMES PSV_DLCS PSM_GAMES PSV_UPDATES PSV_THEMES PSX_GAMES PSP_GAMES"
LIST="${LIST} PSP_DLCS PSP_THEMES PS3_GAMES PS3_DLCS PS3_THEMES PS3_AVATARS"
LIST="${LIST} PS4_GAMES PS4_DLCS PS4_UPDATES PS4_THEMES"
MY_NAME="NoPayStation"

function my_download_file {
    local url="$1"
    local destination="$2"

    case "$DOWNLOADER" in
        "wget")
            wget -O "$destination" "$url" ;;
        "curl")
            curl -o "$destination" "$url" ;;
    esac
}

function downloader_choose {
    if whereis wget > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} wget"
        DOWNLOADER="wget"
    else
        MY_BINARIES="${MY_BINARIES} curl"
        DOWNLOADER="curl"
    fi
}

MY_BINARIES=""
downloader_choose

for bins in $MY_BINARIES
do
    if ! which ${bins} > /dev/null 2>&1
    then
        echo "$bins isn't installed."
        echo "Please install it and try again"
        exit 1
    fi
done

if [ -z "${1}" ]
then
    DEST="$(pwd)"
else
    DEST="${1}"
fi
MY_DATE="$(date "+%d_%m_%Y")"
if [ -f "${DEST}/${MY_NAME}_${MY_DATE}.tar.gz" ]
then
    echo "Backup of the current day already exists. Skipping"
    exit 1
fi

if [ ! -d "${DEST}/${MY_DATE}" ]
then
    mkdir "${DEST}/${MY_DATE}"
fi

for i in $LIST
do
    my_download_file "${HEADER}${BASE_URL}/${MY_URL_PATH}/${i}.tsv" \
                     "${DEST}/${MY_DATE}/${i}.tsv"
done

my_download_file "${HEADER}${BASE_URL}/feed/english.html" \
                 "${DEST}/${MY_DATE}/feed.html"
tar -C "${DEST}" -czf "${DEST}/${MY_NAME}_${MY_DATE}.tar.gz" "${MY_DATE}"

rm -r "${DEST}/${MY_DATE}"
