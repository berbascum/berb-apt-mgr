#!/bin/bash

## Script to manage a multiarch apt repository
#
## Thanks to vacuumbeef <vacuumbeef@vacuumbeef> who was shared to me the 
## procedure to create and sign the repo base structure
#
# Upstream-Name: berb-apt-mgr
#  Source: https://gitlab.com/berbascum/berb-apt-mgr
#
# Copyright (C) 2024 Berbascum <berbascum@ticv.cat>
# All rights reserved.
                                                                                            # BSD 3-Clause License

#################
## Header vars ##
#################
export TOOL_NAME="$(basename ${BASH_SOURCE[0]} | awk -F'.' '{print $1}')"
#TOOL_VERSION="1.0.0.1"
#TOOL_CHANNEL="stable"
TESTED_BASH_VER='5.2.15'

ASK() { echo; read -p "$*" answer; }
info() { echo; echo  "INFO:  $*"; }
abort() { echo; echo "ABORT: $*"; exit; }

## Config file
[ ! -f "apt-repo.conf" ] &&  abort "apt-repo.conf not found!"

## Load config file
while read var; do
    eval ${var}
done < "apt-repo.conf"

fn_help() {
    echo; echo "Script to rebuild an apt repo"
    echo "- This script can be runned from any dir if it's in PATH"
    echo "- Change to the apt repo dir is needed first"
    echo "- The files \"key-ids.conf\" and \"apt-repo.conf\" in /usr/share/berb-apt-mgr"
    echo "  need to be configured and moved to the apt repo rootdir"
    echo "- To create the initial dir structure, run the script with --mkdirs arg"
    echo "- To rebuild repo, run the script with --rebuild tag"
    echo
}
[ -n "$(echo "$@" | grep "\-\-help")" ] && fn_help && exit 0


fn_mkdirs() {
    info "Creating directory structure..."
    mkdir -p pool/main
    for arch in ${arr_archs[@]}; do
        mkdir -p dists/"${suite}"/main/binary-"${arch}"
    done
}
[ -n "$(echo "$@" | grep "\-\-mkdirs")" ] && fn_mkdirs && exit 0

fn_gen_Packages() {
    # First copy debs to pool/main
    for arch in ${arr_archs[@]}; do
	dpkg-scanpackages --multiversion pool/ \
	    > dists/"${suite}"/main/binary-"${arch}"/Packages
        cat dists/${suite}/main/binary-"${arch}"/Packages | gzip -9 \
	    > dists/${suite}/main/binary-"${arch}"/Packages.gz
	## Remove if exist
        [ -f "packages-"${arch}".db" ] && rm -f packages-"${arch}".db
    done
}

fn_gen_Release() {
    apt-ftparchive generate -c=aptftp.conf aptgenerate.conf
    apt-ftparchive release -c=aptftp.conf dists/${suite} >dists/${suite}/Release
}
fn_sign_Release() {
    ## Sign
    gpg -abs -u "${KEY_LONG}" -o dists/${suite}/Release.gpg dists/${suite}/Release
    ## Next shortest is showed at first ilne  with --list-keys --keyid-format long near 
    gpg --export "${KEY_SHORT}" > ${gpg_pub_filename}.gpg
    gpg -u "${KEY_LONG}" --clear-sign \
	--output dists/"${suite}"/InRelease dists/"${suite}"/Release
}

fn_rebuild_repo() {
    if [ -d "pool/main" ]; then
        ASK "Rescan and sign the repo? [ y|n ]: "
        [ "${answer}" != "y" ] && exit
        ## Load key-ids
        [ ! -f "key-ids.conf" ] &&  abort "key-ids.conf not found!"
        while read var; do eval ${var}; done < "key-ids.conf"
        ## Rebuild apt repo
        fn_gen_Packages
        fn_gen_Release
        fn_sign_Release
    fi
}
[ -n "$(echo "$@" | grep "\-\-rebuild")" ] && fn_rebuild_repo && exit 0

