#!/bin/bash

function sha256_choose {
    if which > /dev/null 2>&1
    then
        MY_BINARIES="${MY_BINARIES} sha256"
        SHA256="sha256"
    else
        MY_BINARIES="${MY_BINARIES} sha256sum"
        SHA256="sha256sum"
    fi
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

function check_binaries(){
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
