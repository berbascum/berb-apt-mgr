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

#[HEADER_SECTION]
fn_header_info() {
    BIN_TYPE="bin"
    BIN_SRC_TYPE="bash"
    BIN_SRC_EXT="sh"
    BIN_NAME="berb-apt-mgr"
    URGENCY='optional'
    TESTED_BASH_VER='5.2.15'
}
TOOL_NAME="berb-apt-mgr"
TOOL_VERSION="2.1.0.1"
TOOL_RELEASE="stable"
BBL_GENERAL_VERSION="1101"
BBL_NET_VERSION="1001"
BBL_GIT_VERSION="1231"
#[HEADER_END]

## Args
[ -n "$(echo "$@" | grep "\-\-batch")" ] \
    && BATCH_MODE="True"

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

fn_get_gpg_keyid() {
    info "Checking the key-ids.conf file..."
    ## Load key-ids.conf
    if [ ! -f "key-ids.conf" ]; then
	info "Generating the key-ids.conf file..."
        gpg_key_id="$(gpg --list-keys --with-colons \
	"${gpg_key_username}" | grep "fpr" \
	| sed 's/fpr//g' | sed 's/://g')"
        if [ -z "${gpg_key_id}" ]; then
	    info "Key not found in the user .gnupg"
	    abort "Check gpg username in key-ids.conf"
	fi
	## Create key-ids.conf
	echo "gpg_key_id=\"${gpg_key_id}\"" \
	    > ./key-ids.conf
    fi
    ## Add key-ids.conf to gitignore
    in_gitignore="$(cat .gitignore 2>/dev/null \
        | grep "key-ids.conf")"
    [ -z "${in_gitignore}" ] \
        && echo "key-ids.conf" >> ./.gitignore
    ## Load vars from key-ids.conf
    info "Loading the key-ids.conf file..."
    while read var; do eval ${var}; done < "key-ids.conf"
}

fn_bam_global_conf() {
    ## Load libs
    source /usr/lib/berb-bash-libs/bbl_general_lib_${BBL_GENERAL_VERSION}
    source /usr/lib/berb-bash-libs/bbl_git_lib_${BBL_GIT_VERSION}
    #source /usr/lib/berb-bash-libs/bbl_net_lib_${BBL_NET_VERSION}
    ## Config log
    fn_bbgl_config_log
    ## Config log level
    fn_bbgl_config_log_level $@
    #
    ## Set main config file vars
    CONF_MAIN_FILENAME="${TOOL_NAME}-main.conf"
    CONF_MAIN_FULLPATH="/etc/${TOOL_NAME}"
    CONF_MAIN_FULLPATH_FILENAME="${CONF_MAIN_FULLPATH}/${CONF_MAIN_FILENAME}"
    ## Config main file check
    [ ! -f "${CONF_MAIN_FULLPATH_FILENAME}" ] \
	&&  abort "Main config file not found!"
    ## Load global vars section from main config file
    section="global-vars"
    fn_bbgl_parse_file_section CONF_MAIN "${section}" \
	"load_section"
    #
    ## Templates check
    [ -z "$(ls  ${TEMPLATES_FULLPATH}/*template.conf 2>/dev/null)" ] \
       && abort "Template files not found in ${TEMPLATES_FULLPATH}"
    #
    ## Config local repo check install
    if [ ! -f "${CONF_BERB_REPO_FULLPATH_FILENAME}" ]; then
       info "Local repo conf file not found"
       ASK "Want to create it? [ y|n ]: "
       [ "${answer}" != "y" ] && abort "Aborted by user"
       ## Create local conf file from template
       cp -rv \
	${TEMPLATES_FULLPATH}/${CONF_BERB_REPO_TEMPL_FILENAME} \
	    ./${CONF_BERB_REPO_FILENAME}
    fi
    ## Is configured? Conf local repo
    is_configured=$(cat ./${CONF_BERB_REPO_FILENAME} \
	    | grep "releases_origin=\"some_origin\"")
    [ -n "${is_configured}" ] \
	&& abort "Configure \"./${CONF_BERB_REPO_FILENAME}\" first"
    #
    ## Load global vars section from main config file
    section="global-vars"
    fn_bbgl_parse_file_section CONF_BERB_REPO \
        "${section}" "load_section"
    #
    fn_get_gpg_keyid
    #
    ## Load apt-ftparchive vars section from main conf
    section="apt-ftparchive"
    fn_bbgl_parse_file_section CONF_MAIN "${section}" \
	"load_section"
}
## Load script global config
fn_bam_global_conf

fn_mkdirs() {
    info "Creating directory structure..."
    ## Create pool dirs
    for release in ${arr_releases[@]}; do
	for component in ${arr_components[@]}; do
	    dir="dists/${release}/${component}/source"
            [ -d "${dir}" ] || (mkdir -p -v "${dir}" \
		&& echo "## Ensure tree integrity" \
		> "${dir}/dummy")
	    dir="cache/${release}/${component}"
            [ -d "${dir}" ] || (mkdir -p -v "${dir}" \
		&& echo "## Ensure tree integrity" \
		> "${dir}/dummy")
        done
        for base_dir in ${arr_base_dirs[@]}; do
            for arch in ${arr_archs[@]}; do
	        for component in ${arr_components[@]}; do
	            dir="${base_dir}/${release}/${component}/binary-${arch}"
                    [ -d "${dir}" ] || (mkdir -p -v "${dir}" \
		    && echo "## Ensure tree integrity" \
		    > "${dir}/dummy")
		done
            done
         done
    done
}
[ -n "$(echo "$@" | grep "\-\-mkdirs")" ] && fn_mkdirs && exit 0

fn_conf_filenames_set() {
	## Set aptgen conf file
        file_base=$(echo \
	    "${aptgen_conf_file}"| awk -F'.' '{print $1}')
        file_ext=$(echo \
	    "${aptgen_conf_file}"| awk -F'.' '{print $2}')
        aptgen_conf_full_filename="${file_base}-${release}-${component}.${file_ext}"
	## Set aptftp conf file
	file_base=$(echo \
	    "${aptftp_conf_file}"| awk -F'.' '{print $1}')
        file_ext=$(echo \
	    "${aptftp_conf_file}"| awk -F'.' '{print $2}')
        aptftp_conf_full_filename="${file_base}-${release}.${file_ext}"
}

fn_get_archs_list() {
    ## Set needed vars
    apt_archs_space_list=""
    apt_archs_comma_list=""
    for arch in ${arr_archs[@]}; do
	if [ -z "${apt_archs_space_list}" ]; then
            apt_archs_space_list="\"${arch}\""
        else
            apt_archs_space_list="${apt_archs_space_list} \"${arch}\""
	fi
	if [ -z "${apt_archs_comma_list}" ]; then
            apt_archs_comma_list="${arch}"
        else
            apt_archs_comma_list="${apt_archs_comma_list},${arch}"
	fi
    done
    #echo "apt_archs_space_list=${apt_archs_space_list}"
    #echo "apt_archs_comma_list=${apt_archs_comma_list}"
}

fn_get_components_list() {
    ## Set needed vars
    apt_components_space_list=""
    apt_list_archs_comma_list=""
    for component in ${arr_components[@]}; do
	if [ -z "${apt_components_space_list}" ]; then
            apt_components_space_list="\"${arch}\""
        else
            apt_components_space_list="${apt_components_space_list} \"${component}\""
	fi
	if [ -z "${apt_components_comma_list}" ]; then
            apt_components_comma_list="${component}"
        else
            apt_components_comma_list="${apt_components_comma_list},${component}"
	fi
    done
}

fn_apt_repo_configs_create() {
    ## Ask for dirs creation
    ASK "Want to call the --mkdirs flag? [ y|n ]: "
    [ "${answer}" == "y" ] && fn_mkdirs
    ## Check for apt-ftp config s dir
    ASK "Any previous aptftp and aptgenerate conf files will be removed. Are you sure? [ y|n ]: "
    [ "${answer}" != "y" ] && abort "Aborted by user"
    if [ -d "${apt_conf_dir}" ]; then
	rm -fv ${apt_conf_dir}/*.conf #2>/dev/null
    else
        mkdir -p -v "${apt_conf_dir}"
    fi
    if [ -d "${apt_conf_dir}/fragments" ]; then
	rm -fv ${apt_conf_dir}/fragments/* #2>/dev/null
    else
        mkdir -p -v "${apt_conf_dir}"/fragments
    fi
    #
    fn_get_archs_list
    fn_get_components_list
    #
    for release in ${arr_releases[@]}; do
        for component in ${arr_components[@]}; do
	    ## Set per release and per component apt conf files
	    fn_conf_filenames_set
            ## Create the aptgenerate global shared config
            ## conf file from template, one file per release
            cp -v "${aptgen_templ_file}" \
	        "${apt_conf_dir}/${aptgen_conf_full_filename}"
            sed -i "s/REPLACE_TOOL_VERSION/${TOOL_VERSION}/g" \
	        "${apt_conf_dir}/${aptgen_conf_full_filename}"
            sed -i "s/REPLACE_TOOL_RELEASE/${TOOL_RELEASE}/g" \
	        "${apt_conf_dir}/${aptgen_conf_full_filename}"
            sed -i "s/REPLACE_RELEASE/${release}/g" \
	        "${apt_conf_dir}/${aptgen_conf_full_filename}"
            sed -i "s/REPLACE_COMPONENT/${component}/g" \
	        "${apt_conf_dir}/${aptgen_conf_full_filename}"
            ## Create aptconf BinDir fragments
	    ## and merge in aptgenerate.conf
            for arch in ${arr_archs[@]}; do
	        aptconf_BinDir_frag="${apt_conf_dir}/fragments/aptconf-BinDir-${release}-${component}-${arch}.fragment"
                cp -v "${aptconf_BinDir_templ_file}" \
		"${aptconf_BinDir_frag}"
                sed -i "s/REPLACE_RELEASE/${release}/g" \
		    "${aptconf_BinDir_frag}"
                sed -i "s/REPLACE_ARCH/${arch}/g" \
		    "${aptconf_BinDir_frag}"
                sed -i "s/REPLACE_COMPONENT/${component}/g" \
		    "${aptconf_BinDir_frag}"
                cat "${aptconf_BinDir_frag}" >> \
	            "${apt_conf_dir}/${aptgen_conf_full_filename}"
            done
            ## Create aptconf SrcDir fragments
	    ## and merge in aptgenerate.conf
	    aptconf_SrcDir_frag="${apt_conf_dir}/fragments/aptconf-SrcDir-${release}-${component}.fragment"
            cp -v "${aptconf_SrcDir_templ_file}" \
	        "${aptconf_SrcDir_frag}"
            sed -i "s/REPLACE_RELEASE/${release}/g" \
	        "${aptconf_SrcDir_frag}"
            sed -i "s/REPLACE_COMPONENT/${component}/g" \
	        "${aptconf_SrcDir_frag}"
            cat "${aptconf_SrcDir_frag}" >> \
	        "${apt_conf_dir}/${aptgen_conf_full_filename}"
            ## Create aptconf Tree fragments
	    ## and merge in aptgenerate.conf
	    aptconf_Tree_frag="${apt_conf_dir}/fragments/aptconf-Tree-${release}-${component}.fragment"
            cp -v "${aptconf_Tree_templ_file}" \
	        "${aptconf_Tree_frag}"
            sed -i "s/REPLACE_RELEASE/${release}/g" \
	        "${aptconf_Tree_frag}"
            sed -i "s/replace_archs_list/${apt_archs_space_list}/g" \
	        "${aptconf_Tree_frag}"
            sed -i "s/REPLACE_COMPONENT/${component}/g" \
	        "${aptconf_Tree_frag}"
            cat "${aptconf_Tree_frag}" >> \
	        "${apt_conf_dir}/${aptgen_conf_full_filename}"
	done ## Components
        #
        ## Create the base aptftp config from template
        ## one per release and component
        cp -v "${aptftp_templ_file}" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i "s/REPLACE_TOOL_VERSION/${TOOL_VERSION}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i "s/REPLACE_TOOL_RELEASE/${TOOL_RELEASE}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i "s/REPLACE_RELEASE/${release}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i "s/REPLACE_ORIGIN/${releases_origin}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i "s/REPLACE_LABEL/${releases_label}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i \
	    "s/REPLACE_DESC/${releases_description}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i \
	    "s/replace_archs_list/${apt_archs_space_list}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
        sed -i \
	    "s/replace_components_list/${apt_components_space_list}/g" \
	    "${apt_conf_dir}/${aptftp_conf_full_filename}"
    done ## Releases
    ## Create the apt list from template
    if [ ! -f "${gpg_pub_filename}.list" ]; then
	info "Creating \"${gpg_pub_filename}.list\"..."
        cp "${apt_template_list_fullpath_filename}" \
	    "${gpg_pub_filename}.list"
        sed -i "s/REPLACE_ARCHS/${apt_archs_comma_list}/g" \
	    "${gpg_pub_filename}.list"
        sed -i "s/REPLACE_FILENAME/${gpg_pub_filename}/g" \
	    "${gpg_pub_filename}.list"
        sed -i "s|REPLACE_URL|${apt_list_url}|g" \
	    "${gpg_pub_filename}.list"
    fi

    ## Remove fragments dir after merge them
    rm -r "${apt_conf_dir}"/fragments
}
[ -n "$(echo "$@" | grep "\-\-createconf")" ] \
    && fn_apt_repo_configs_create && exit 0

fn_gen_Packages() {
    ## First copy the debs to pool/<release>/main/binary-<arch>
    #
    for release in ${arr_releases[@]}; do
	for component in ${arr_components[@]}; do
	    ## Set per release and component apt conf files
	    fn_conf_filenames_set
	    ## Create Packages and Content
	    info "Generating \"Packages\" for \"${release}\" and component \"${component}\"..."
	    apt-ftparchive generate \
	        -c=${apt_conf_dir}/${aptftp_conf_full_filename} \
	        ${apt_conf_dir}/${aptgen_conf_full_filename}
	done
    done
}

fn_gen_Release() {
    for release in ${arr_releases[@]}; do
        ## Set per release apt conf files
        fn_conf_filenames_set
        ## Create Releases
	info "Generating \"Release\" for \"${release}\"..."
        apt-ftparchive release \
	 -c=${apt_conf_dir}/${aptftp_conf_full_filename} \
	    dists/${release} > dists/${release}/Release
    done
}

fn_sign_Release() {
    for release in ${arr_releases[@]}; do
        info "Signing \"Release\" for \"${release}\"..."
        if [ "${SCRIPT_CALLER}" == "github" ]; then
            ## Sign
            gpg --batch --yes --debug-level advanced --passphrase "${GPG_PASSPHRASE}" -abs -u "${gpg_key_id}" -o dists/${release}/Release.gpg dists/${release}/Release
        gpg --batch --yes --debug-level advanced --passphrase "${GPG_PASSPHRASE}" -u "${gpg_key_id}" --clear-sign --output dists/"${release}"/InRelease dists/"${release}"/Release
        else
            ## Sign
            gpg --batch --yes --debug-level advanced -abs -u "${gpg_key_id}" -o dists/${release}/Release.gpg dists/${release}/Release
            gpg --batch --yes --debug-level advanced -u "${gpg_key_id}" --clear-sign --output dists/"${release}"/InRelease dists/"${release}"/Release
        fi
    done
    ## Next shortest is showed at first ilne with 
    ## --list-keys --keyid-format long near 
}

fn_commit_changes() {
	#
        ## Default commit msg used for --batch mode
        commit_msg="Rebuild repository"
        ## Interactive mode:
        if [ "${BATCH_MODE}" != "True" ]; then
	    ## Ask to commit and push rebuild changes
            ASK "Commit the rebuild? [ y|n ]: "
            [ "${answer}" != "y" ] && exit 10
            ## Ask for commit msg suffix
            ASK "Type a short commit msg or leave empty: "
            [ -n "${answer}" ] \
                && commit_msg="${commit_msg}: ${answer}"
        fi
        ## Add and commit
	git add cache dists
        fn_bblgit_check_if_can_sign
        eval "${GIT_COMMIT_CMD}"
        ## Interactive mode:
        if [ "${BATCH_MODE}" != "True" ]; then
            ## Ask for push to origin
            ASK "Want to push main to origin? [ y|n ]: "
            [ "${answer}" != "y" ] && exit
        fi
	## Push main to origin
        git push origin main
}

fn_gpg_pubkey_export() {
    info "Exporting \"${gpg_pub_filename}.gpg\"..."
    gpg --export "${gpg_key_id}" > ${gpg_pub_filename}.gpg
}

fn_rebuild_repo() {
    if [ -d "pool" ]; then
        if [ "${BATCH_MODE}" != "True" ]; then
            ASK "Rescan and sign the repo? [ y|n ]: "
            [ "${answer}" != "y" ] && exit 10
        fi
        ## Clean cache databases in cache/release/component
        rm -fv cache/*/*/packages-*.db
        ## Clean dists dir files
        rm -fv dists/*/InRelease
        rm -fv dists/*/Release*
        rm -fv dists/*/*/Contents-*.*
        rm -fv dists/*/*/*/Packages.*
        ## Rebuild apt repo
        fn_gen_Packages
        fn_gen_Release
        fn_sign_Release
        [ -z "$(echo "$@" | grep "\-\-pubkey-export")" ] || fn_gpg_pubkey_export
        [ -z "$(echo "$@" | grep "\-\-commit")" ] || fn_commit_changes
    fi
}
[ -n "$(echo "$@" | grep "\-\-rebuild")" ] \
    && fn_rebuild_repo $@ && exit 0
