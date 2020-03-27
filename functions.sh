#!/bin/bash

ext="7z"
mime_type="application/x-7z-compressed"

sha256_choose() {
    if which sha256 > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} sha256"
        SHA256="sha256"
    else
        MY_BINARIES="${MY_BINARIES} sha256sum"
        SHA256="sha256sum"
    fi
}

my_sha256() {
    local file="${1}"

    case "$SHA256" in
        "sha256sum")
        sha256sum "${file}" | awk '{ print $1 }' ;;
        "sha256")
        sha256    "${file}" | awk '{ print $4 }' ;;
    esac
}

downloader_choose() {
    if which wget > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} wget"
        DOWNLOADER="wget"
    else
        MY_BINARIES="${MY_BINARIES} curl"
        DOWNLOADER="curl"
    fi
}

my_download_file() {
    local url="${1}"
    local destination="${2}"

    case "${DOWNLOADER}" in
        "wget")
        wget -O "${destination}" "${url}" ;;
        "curl")
        curl -o "${destination}" "${url}" ;;
    esac
}

check_binaries(){
    local BINARIES="${1}"
    for bins in ${BINARIES}
    do
        if ! which ${bins} > /dev/null 2>&1
        then
            echo "${bins} isn't installed."
            echo "Please install it and try again"
            exit 1
        fi
    done
}

region_rename() {
    local NAME="${1}"

    if echo "${NAME}" | grep -q "\[USA\]"
    then
        local NEW_NAME="$(echo "${NAME}" | sed 's/USA/NTSC/g')"
    elif echo "${NAME}" | grep -q "\[JPN\]"
    then
        NEW_NAME="$(echo "${NAME}" | sed 's/JPN/NTSC-J/g')"
    elif echo "${NAME}" | grep -q "\[EUR\]"
    then
        NEW_NAME="$(echo "${NAME}" | sed 's/EUR/PAL/g')"
    elif echo "${NAME}" | grep -q "\[ASA\]"
    then
        NEW_NAME="$(echo "${NAME}" | sed 's/ASA/NTSC-C/g')"
    fi
    echo ${NEW_NAME}
}

check_valid_psv_id() {
    local TITLE_ID="${1}"
    if ! echo "${TITLE_ID}" | grep -q -E -i 'PCS[ABCDEFGH][0-9]{5}'
    then
        echo ""
        echo "Error"
        echo "Media ID is not valid."
        echo "It should be the following format:"
        echo "PCSA01234"
        echo "Check your first parameter."
        exit 1
    fi
}

check_valid_psp_id() {
    local TITLE_ID="${1}"
    if ! echo "${TITLE_ID}" | grep -q -E -i '[NU][PCL][UJEHA][DFGHJQSXZ][0-9]{5}'
    then
        echo ""
        echo "Error"
        echo "Media ID is not valid."
        echo "It should be the following format:"
        echo "NPUF00001"
        echo "Check your first parameter."
        exit 1
    fi
}

yesno_checksum() {
    local GAME_ID="${1}"
    while true
    do
        echo "Do you want to continue? (yes/no)"
        read INPUT
        case "${INPUT}" in
            Yes|YES|yes|Y|y)
                break
                ;;
            No|NO|no|n)
                echo "User aborted."
                test -e "${GAME_ID}.pkg" && rm "${GAME_ID}.pkg"
                if [ ${?} -eq 0 ]
                then
                    echo "Downloaded file removed."
                else
                    echo "Something went wrong while removing pkg file."
                fi
                exit 1
                ;;
        esac
    done
}
exit_if_fail() {
    local _msg="${1}"
    if [ "${?}" -ne 0 ]
    then
        echo "${_msg}"
        exit 1
    fi
}

check_announce_url() {
    local URL="${1}"
    echo "${URL}" | grep "^http" &> /dev/null
    if [ ${?} -ne 0 ]
    then
        echo "No valid announce url provided. Be sure that the url starts with \"http\" and has a correct hostname"
        exit 1
    fi
}

compare_checksum(){
    local LIST="${1}"
    local FILE="${2}"
    if [ -n "${LIST}" ]
    then
        if [ "${FILE}" != "${LIST}" ]
        then
            echo "Checksum of downloaded file does not match checksum in list"
            echo "${FILE} != ${LIST}"
            yesno_checksum
        fi
    else
        echo "No checksum available in *.tsv list."
        echo "Maybe you could report it:"
        echo "\"${FILE}\""
        echo ""
    fi
}
