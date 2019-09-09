#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>
# Version 0.3

my_usage(){
    echo ""
    echo "Usage:"
    echo "${0} \"/path/to/DLC.tsv\" \"PCSE00986\""
}

function my_sha256 {
    local file="${1}"

    case "$SHA256" in
        "sha256sum")
            sha256sum "${file}" | awk '{ print $1 }' ;;
        "sha256")
            sha256    "${file}" | awk '{ print $4 }' ;;
    esac
}

function sha256_choose {
    if which sha256 > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} sha256"
        SHA256="sha256"
    else
        MY_BINARIES="${MY_BINARIES} sha256sum"
        SHA256="sha256sum"
    fi
}

function my_download_file {
    local url="${1}"
    local destination="${2}"

    case "${DOWNLOADER}" in
        "wget")
            wget -O "${destination}" "${url}" ;;
        "curl")
            curl -o "${destination}" "${url}" ;;
    esac
}

function downloader_choose {
    if which wget > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} wget"
        DOWNLOADER="wget"
    else
        MY_BINARIES="${MY_BINARIES} curl"
        DOWNLOADER="curl"
    fi
}


MY_BINARIES="pkg2zip sed"
sha256_choose; downloader_choose
for bins in ${MY_BINARIES}
do
    if ! which "${bins}" > /dev/null 2>&1
    then
        echo "${bins} isn't installed."
        echo "Please install it and try again"
        exit 1
    fi
done

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

LIST="$(grep "^${GAME_ID}" "${TSV_FILE}" | sed 's/.*http/http/' | tr '\n' "|" \
        | tr '\r' "%" | sed 's^%^^g')"

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

i=1
max="$(echo "$(echo "${LIST}" | grep -o "|" | wc -l) + 1" | bc)"

while [ "${i}" -ne "${max}" ]
do
    item="$(echo "${LIST}" | awk -F "|" "{ print \$$i }")"
    i="$(echo "$i + 1" | bc)"
    echo "${item}"

    LINK="$(echo "${item}" | awk '{ print $1 }')"
    LIST_SHA256="$(echo "${item}" | awk '{ print $3 }')"
    if [ ! -d "${MY_PATH}/${DESTDIR}_update" ]
    then
        mkdir "${MY_PATH}/${DESTDIR}_update"
    fi
    cd "${MY_PATH}/${DESTDIR}_update"
    my_download_file "$LINK" "${GAME_ID}_update.pkg"
    FILE_SHA256="$(my_sha256 "${GAME_ID}_update.pkg")"
    if [ "${FILE_SHA256}" != "${LIST_SHA256}" ]
    then
        echo "Checksum of downloaded file does not match checksum in list"
        echo "${FILE_SHA256} != ${LIST_SHA256}"
        LOOP=1
        while [ ${LOOP} -eq 1 ]
        do
            echo "Do you want to continue? (yes/no)"
            read INPUT
            if [ ${INPUT} == "yes" ]
            then
                LOOP=0
            elif [ ${INPUT} == "no" ]
            then
                LOOP=0
                echo "User aborted."
                echo "Downloaded file removed."
                rm "${GAME_ID}_update.pkg"
                exit 1
            fi
        done
    fi
    pkg2zip "${GAME_ID}_update.pkg"
    rm "${GAME_ID}_update.pkg"
    cd "${MY_PATH}"
done
