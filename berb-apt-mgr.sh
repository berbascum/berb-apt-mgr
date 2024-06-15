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
error() { echo; echo "ABORT: $*"; exit; }

## Help
fn_help() {
    echo; echo "Simple script to manage a multiarch and multirelease apt repository"
    echo
    echo "* This script can be runned from any dir if it's in PATH"
    echo
    echo "* Change to the apt repo dir is needed first"
    echo
    echo "* The files \"key-ids.conf\" and \"berb-apt-mgr.conf\" in /usr/share/berb-apt-mgr"
    echo "  need to be configured and moved to the apt repo rootdir"
    echo
    echo "* script tags:"
    echo
    echo "  --mkdirs:     Creates the repo dir structure, based on the releases and archs"
    echo "                configured in the berb-apt-mgr.conf file"
    echo
    echo "  --rebuild:    Rebuilds the repo"
    echo
    echo "  --createconf: Generates the aptftp.conf and aptgenerate.conf files from"
    echo "                temples using the releases and archs configured in the"
    echo "                berb-apt-mgr.conf file"
    echo
}
[ -z "$1" -o -n "$(echo "$@" | grep "\-\-help")" ] && fn_help && exit 0

## Config file
[ ! -f "berb-apt-mgr.conf" ] &&  abort "berb-apt-mgr.conf not found!"
[ ! -f "/etc/berb-apt-mgr/berb-apt-mgr-main.conf" ] \
    &&  abort "/etc/berb-apt-mgr/berb-apt-mgr-main.conf not found!"

## Load main config file
while read var; do
    eval ${var}
done < "/etc/berb-apt-mgr/berb-apt-mgr-main.conf"
## Load config file
while read var; do
    eval ${var}
done < "berb-apt-mgr.conf"

fn_mkdirs() {
    info "Creating directory structure..."
    ## Create pool dirs
    for release in ${arr_releases[@]}; do
        mkdir -p -v "dists/${release}/main/source"
        for base_dir in ${arr_base_dirs[@]}; do
            for arch in ${arr_archs[@]}; do
                mkdir -p -v "${base_dir}/${release}/main/binary-${arch}"
            done
         done
    done
    mkdir -v state cache
}
[ -n "$(echo "$@" | grep "\-\-mkdirs")" ] && fn_mkdirs && exit 0


fn_check_templates() {
    for template in ${arr_aptconf_templates[@]}; do
        [ ! -f "${template}" ] && error "\"${template}\" template not found!"
    done
}

fn_get_arch_lists() {
    ## Set needed vars
    architectures_archs_list=""
    apt_list_archs_list=""
    for arch in ${arr_archs[@]}; do
	if [ -z "${architectures_archs_list}" ]; then
            architectures_archs_list="\"${arch}\""
        else
            architectures_archs_list="${architectures_archs_list} \"${arch}\""
	fi
	if [ -z "${apt_list_archs_list}" ]; then
            apt_list_archs_list="${arch}"
        else
            apt_list_archs_list="${apt_list_archs_list},${arch}"
	fi
    done
    #echo "architectures_archs_list=${architectures_archs_list}"
    #echo "apt_list_archs_list=${apt_list_archs_list}"
}
fn_apt_repo_configs_create() {
    ## Ask for dirs creation
    ASK "Want to call the --mkdirs flag? [ y|n ]: "
    [ "${answer}" == "y" ] && fn_mkdirs
    ## Check for apt-ftp config s dir
    ASK "Any previous aptftp and aptgenerate conf files will be removed. Are you sure? [ y|n ]: "
    [ "${answer}" != "y" ] && abort "Aborted by user"
    if [ -d "${apt_conf_dir}/fragments" ]; then
	rm ${apt_conf_dir}/*.conf 2>/dev/null
	rm ${apt_conf_dir}/fragments/* 2>/dev/null
    else
        mkdir -p -v "${apt_conf_dir}"/fragments
    fi
    #
    fn_get_arch_lists
    #
    ## Check for apt-ftp config templates
    fn_check_templates
    #
    ## Create the aptgenerate config file base from the template, no need replacements
    cp -v "${aptgen_templ_file}" "${apt_conf_dir}/${aptgen_conf_filename}"
    #
    ## Create the config fragments nedded to string replacement for each release and archin berb conf
    for release in ${arr_releases[@]}; do
        ## Create aptftp conf fragments and merge in aptftp.conf
	aptftp_conf_frag="${apt_conf_dir}/fragments/aptftp-conf-${release}.fragment"
        cp -v "${aptftp_templ_file}" "${aptftp_conf_frag}"
        sed -i "s/REPLACE_RELEASE/${release}/g" "${aptftp_conf_frag}"
        sed -i "s/REPLACE_ORIGIN/${releases_origin}/g" "${aptftp_conf_frag}"
        sed -i "s/REPLACE_LABEL/${releases_label}/g" "${aptftp_conf_frag}"
        sed -i "s/REPLACE_DESCRIPTION/${releases_description}/g" "${aptftp_conf_frag}"
        sed -i "s/replace_archs_list/${architectures_archs_list}/g" "${aptftp_conf_frag}"
        cat "${aptftp_conf_frag}" >> "${apt_conf_dir}/${aptftp_conf_filename}"
        ## Create aptconf BinDir fragments and merge in aptgenerate.conf
        for arch in ${arr_archs[@]}; do
	    aptconf_BinDir_frag="${apt_conf_dir}/fragments/aptconf-BinDir-${release}-${arch}.fragment"
            cp -v "${aptconf_BinDir_templ_file}" "${aptconf_BinDir_frag}"
            sed -i "s/REPLACE_RELEASE/${release}/g" "${aptconf_BinDir_frag}"
            sed -i "s/REPLACE_ARCH/${arch}/g" "${aptconf_BinDir_frag}"
            cat "${aptconf_BinDir_frag}" >> "${apt_conf_dir}/${aptgen_conf_filename}"
        done
        ## Create aptconf SrcDir fragments and merge in aptgenerate.conf
	aptconf_SrcDir_frag="${apt_conf_dir}/fragments/aptconf-SrcDir-${release}.fragment"
        cp -v "${aptconf_SrcDir_templ_file}" "${aptconf_SrcDir_frag}"
        sed -i "s/REPLACE_RELEASE/${release}/g" "${aptconf_SrcDir_frag}"
        sed -i "s/REPLACE_ARCH/${arch}/g" "${aptconf_SrcDir_frag}"
        cat "${aptconf_SrcDir_frag}" >> "${apt_conf_dir}/${aptgen_conf_filename}"
        ## Create aptconf Tree fragments and merge in aptgenerate.conf
	aptconf_Tree_frag="${apt_conf_dir}/fragments/aptconf-Tree-${release}.fragment"
        cp -v "${aptconf_Tree_templ_file}" "${aptconf_Tree_frag}"
        sed -i "s/REPLACE_RELEASE/${release}/g" "${aptconf_Tree_frag}"
        sed -i "s/replace_archs_list/${architectures_archs_list}/g" "${aptconf_Tree_frag}"
        cat "${aptconf_Tree_frag}" >> "${apt_conf_dir}/${aptgen_conf_filename}"
    done
    ## Create the apt list from template
    if [ ! -f "${gpg_pub_filename}.list" ]; then
        cp "${apt_template_list_fullpath_filename}" "${gpg_pub_filename}.list"
        sed -i "s/REPLACE_ARCHS/${apt_list_archs_list}/g" "${gpg_pub_filename}.list"
        sed -i "s/REPLACE_FILENAME/${gpg_pub_filename}/g" "${gpg_pub_filename}.list"
    fi
}
[ -n "$(echo "$@" | grep "\-\-createconf")" ] && fn_apt_repo_configs_create && exit 0

fn_gen_Packages() {
    ## First copy the debs to pool/<release>/main
    #
    ## Remove the packages files in the repo rootdirn
    [ -f "packages-"${arch}".db" ] && rm -f packages-"${arch}".db
    ## Gen Packages files for each arch and release
    for release in ${arr_releases[@]}; do
        for arch in ${arr_archs[@]}; do
	    dpkg-scanpackages --multiversion pool/ \
	        > dists/"${release}"/main/binary-"${arch}"/Packages
            cat dists/${release}/main/binary-"${arch}"/Packages | gzip -9 \
	        > dists/${release}/main/binary-"${arch}"/Packages.gz
	done
    done
}

fn_gen_Release() {
        apt-ftparchive generate -c=${apt_conf_dir}/aptftp.conf \
	    ${apt_conf_dir}/aptgenerate.conf
    for release in ${arr_releases[@]}; do
        apt-ftparchive release -c=${apt_conf_dir}/aptftp.conf dists/${release} >dists/${release}/Release
    done
}

fn_sign_Release() {
    for release in ${arr_releases[@]}; do
        ## Sign
        gpg -abs -u "${KEY_LONG}" -o dists/${release}/Release.gpg dists/${release}/Release
        gpg -u "${KEY_LONG}" --clear-sign \
	    --output dists/"${release}"/InRelease dists/"${release}"/Release
    done
    ## Next shortest is showed at first ilne  with --list-keys --keyid-format long near 
    gpg --export "${KEY_SHORT}" > ${gpg_pub_filename}.gpg
}

fn_rebuild_repo() {
    if [ -d "pool" ]; then
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

