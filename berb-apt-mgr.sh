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
    echo; echo "Script to rebuild an apt repo"
    echo "- This script can be runned from any dir if it's in PATH"
    echo "- Change to the apt repo dir is needed first"
    echo "- The files \"key-ids.conf\" and \"berb-apt-mgr.conf\" in /usr/share/berb-apt-mgr"
    echo "  need to be configured and moved to the apt repo rootdir"
    echo "- To create the initial dir structure, run the script with --mkdirs arg"
    echo "- To rebuild repo, run the script with --rebuild tag"
    echo
}
[ -n "$(echo "$@" | grep "\-\-help")" ] && fn_help && exit 0

## Config file
[ ! -f "berb-apt-mgr.conf" ] &&  abort "berb-apt-mgr.conf not found!"

## Load config file
while read var; do
    eval ${var}
done < "berb-apt-mgr.conf"

fn_mkdirs() {
    info "Creating directory structure..."
    ## Create pool dirs
    for base_dir in ${arr_base_dirs[@]}; do
        for release in ${arr_releases[@]}; do
            for arch in ${arr_archs[@]}; do
                mkdir -p -v "${base_dir}/${release}/main/binary-${arch}"
            done
         done
    done
}
[ -n "$(echo "$@" | grep "\-\-mkdirs")" ] && fn_mkdirs && exit 0

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
    ## Check for apt-ftc config s dir
    ASK "Any previous aptftp and aptgenerate conf files will be removed. Are you sure? [ y|n ]: "
    [ "${answer}" != "y" ] && abort "Aborted by user"
    if [ -d "${apt_ftp_config_dirname}/fragments" ]; then
	rm ${apt_ftp_config_dirname}/*.conf 2>/dev/null
	rm ${apt_ftp_config_dirname}/fragments/* 2>/dev/null
    else
        mkdir -p -v "${apt_ftp_config_dirname}"/fragments
    fi
    #
    fn_get_arch_lists
    #
    ## Check for apt-ftp config templates
    fn_check_templates
    ## Create aptftp config file from the template
    cp -v "${aptftp_conf_templ_fullpath_filename}" "${apt_ftp_config_dirname}/${aptftp_conf_filename}"
    #
    ## Create aptgenerate config files from the template for each release and arch
    for release in ${arr_releases[@]}; do
        cp -v "${aptftp_conf_release_templ_fullpath_filename}" \
	    "${apt_ftp_config_dirname}/fragments/aptftp-conf-release-${release}.fragment"
        sed -i "s/REPLACE_RELEASE/${release}/g" \
	    "${apt_ftp_config_dirname}/fragments/aptftp-conf-release-${release}.fragment"
        sed -i "s/REPLACE_ORIGIN/${releases_origin}/g" \
	    "${apt_ftp_config_dirname}/fragments/aptftp-conf-release-${release}.fragment"
        sed -i "s/REPLACE_LABEL/${releases_label}/g" \
	    "${apt_ftp_config_dirname}/fragments/aptftp-conf-release-${release}.fragment"
        sed -i "s/REPLACE_DESCRIPTION/${releases_description}/g" \
	    "${apt_ftp_config_dirname}/fragments/aptftp-conf-release-${release}.fragment"
        sed -i "s/replace_archs_list/${architectures_archs_list}/g" \
	    "${apt_ftp_config_dirname}/fragments/aptftp-conf-release-${release}.fragment"
    done
    exit
    for release in ${arr_releases[@]}; do
        for arch in ${arr_archs[@]}; do
            conf_fragment=$(echo "${aptgenerate_conf_filename_noext}-${release}-${arch}.conf")
            cp -v "${aptgenerate_conf_templ_fullpath_filename}" \
	        "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}"
            sed -i "s/REPLACE_ARCH/${arch}/g" \
	        "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}"
            sed -i "s/REPLACE_RELEASE/${release}/g" \
	        "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}"
            sed -i "s/REPLACE_ORIGIN/${releases_origin}/g" \
	        "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}"
            sed -i "s/REPLACE_LABEL/${releases_label}/g" \
	        "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}"
            sed -i "s/REPLACE_DESCRIPTION/${releases_description}/g" \
	        "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}"
            sed -i "s/replace_archs_list/${architectures_archs_list}/g" \
	        "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}"
	    cat "${apt_ftp_config_dirname}/fragments/${aptgenerate_conf_fragment}" \
		>> "${apt_ftp_config_dirname}/${aptgenerate_conf_filename}"
	    echo "" >> "${apt_ftp_config_dirname}/${aptgenerate_conf_filename}"
        done
    done
}
[ -n "$(echo "$@" | grep "\-\-createconf")" ] && fn_apt_repo_configs_create && exit 0

fn_gen_Release() {
    for release in ${arr_releases[@]}; do
        for arch in ${arr_archs[@]}; do
            [ "aptftp-${release}-${arch}.conf" ] && fn_gen_apt_configs_from_templates
        done
    done
    exit

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
    if [ -d "pool" ]; then
        ASK "Rescan and sign the repo? [ y|n ]: "
        [ "${answer}" != "y" ] && exit
        ## Load key-ids
        [ ! -f "key-ids.conf" ] &&  abort "key-ids.conf not found!"
        while read var; do eval ${var}; done < "key-ids.conf"
        ## Rebuild apt repo
        #fn_gen_Packages
        fn_gen_Release
        fn_sign_Release
    fi
}
[ -n "$(echo "$@" | grep "\-\-rebuild")" ] && fn_rebuild_repo && exit 0

