#!/usr/bin/env bash
# setup-copyparty_sync.sh
# Install copyparty_sync on a Linux system
#
# Author: Sam Saint-Pettersen, October 2025.
# https://stpettersen.xyz
#
# Usage: wget -qO - https://sh.homelab.stpettersen.xyz/copyparty-sync/setup-copyparty_sync.sh | sudo bash
#
# OR SAFER WAY, INSPECTING THE SCRIPT CONTENTS BEFORE RUNNING:
# > wget -O setup-slax.sh https://sh.homelab.stpettersen.xyz/copyparty_sync/setup-copyparty_sync.sh
# > cat setup-copyparty_sync.sh
# > sudo bash setup-copyparty_sync.sh

# Define the server root for assets served by this script.
server="https://sh.homelab.stpettersen.xyz/copyparty-sync"

check_is_root() {
    if (( EUID != 0 )); then
        echo "Please run this as root (sudo/doas)."
        exit 1
    fi
}

sha256cksm() {
    local status
    local cksum_file
    cksum_file=$1
    cksum_file="${cksum_file%.*}_sha256.txt"
    wget -q "${server}/${cksum_file}"
    sha256sum -c "${cksum_file}" > /dev/null 2>&1
    status=$?
    if (( status == 1 )); then
        echo "SHA256 checksum failed for '${1}'."
        echo "Aborting..."
        rm -f "${cksum_file}"
        exit 1
    else
        echo "SHA256 checksum OK for '${1}'."
    fi
    rm -f "${cksum_file}"
}

script_cksm() {
    if [[ ! -f "setup-copyparty_sync.sh" ]]; then
        wget -q "${server}/setup-copyparty_sync.sh"
    fi
    sha256cksm "setup-copyparty_sync.sh"
    if [[ $(basename "$0") != "setup-copyparty_sync.sh" ]]; then
        rm -f setup-copyparty_sync.sh
    fi
}

is_musl() {
    local musl
    musl=$(find /lib -iname '*ld-musl*.so*' 2> /dev/null)
    if [[ -n $musl ]]; then
        return 1 # true
    fi
    return 0 # false
}

main() {
    check_is_root
    # Get machine architecture
    local arch
    arch=$(uname -m)
    if [[ $arch == "x86_64" ]]; then
        arch="amd64"
    elif [[ $arch == "aarch64" ]]; then
        arch="aarch64"
    fi
    local archive
    archive="copyparty_sync_linux_${arch}.tar.gz"
    local m
    is_musl
    m=$?
    if (( m == 1 )); then
        archive="copyparty_sync_linux_${arch}_musl.tar.gz"
    fi
    echo "Installing copyparty_sync (Linux ${arch})..."
    script_cksm
    if [[ -f "${archive}" ]]; then
        rm -f "${archive}"
    fi
    wget -q "${server}/${archive}"
    sha256cksm "${archive}"
    tar -xzf "${archive}"
    rm -f "${archive}"
    mkdir -p /etc/copyparty_sync
    mkdir -p /usr/share/copyparty_sync
    mv copyparty_sync /usr/local/bin
    chmod +x /usr/local/bin/copyparty_sync
    mv LICENSE /usr/share/copyparty_sync
    echo "Done."
    exit 0
}

main
