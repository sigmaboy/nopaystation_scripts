#!/bin/bash

sha256_choose() {
    if which > /dev/null 2>&1
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

function region_rename() {
    local NAME="${1}"

    if echo "${NAME}" | grep -q "[USA]"
    then
        local NEW_NAME="$(echo "${NAME}" | sed 's/USA/NTSC/g')"
    elif echo "${NAME}" | grep -q "[JPN]"
    then
        NEW_NAME="$(echo "${NAME}" | sed 's/JPN/NTSC-J/g')"
    elif echo "${NAME}" | grep -q "[EUR]"
    then
        NEW_NAME="$(echo "${NAME}" | sed 's/EUR/PAL/g')"
    elif echo "${NAME}" | grep -q "[ASA]"
    then
        NEW_NAME="$(echo "${NAME}" | sed 's/ASA/NSTC-U/g')"
    else
        echo "Region not found."
        exit 1
    fi
    echo ${NEW_NAME}
}
