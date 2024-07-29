# Another bash script to manage an apt repo
Simple bash script to manage a configurable multiarch and multirelease apt repository

### Fetures
- Multiarch
- Multi-release
- APT repo irectory tree creation (--mkdirs flag)
- Config files for apt-ftparchive creation (--createconf flag)
- Packages creation per release and arch
- Release creation per release and arch
- Release and InRelease signing
- Pug gpg keyring exportation
- Repo sources.list creation
- After generating a new dir tree and createconfig,  run with --rebuild to regenerate all
- After adding new packages to any pool, run with --rebuild to regenerate all


### version 2.0.3.1-stable
- Fix: multi-release feature
- New: on --rebuild feature, ask for a extra commit info before committing the rebuild changes

### version 2.0.2.1-stable
- Broken: multi-release feature

## Installation
The script can be installed from [berbascum's git apt repo](https://github.com/berbascum/berb-apt-git-repo)


## Help
* This script can be runned from any dir in PATH

* Change to the apt repo dir is needed first

* The files \"key-ids.conf\" and \"berb-apt-mgr.conf\" in /usr/share/berb-apt-mgr need to be configured and moved to the apt repo rootdir

* script tags:

  --mkdirs:     Creates the repo dir structure, based on the releases and archs"
                configured in the berb-apt-mgr.conf file"

  --rebuild:    Rebuilds the repo"

  --createconf: Generates the aptftp.conf and aptgenerate.conf files from"
                temples using the releases and archs configured in the"
                berb-apt-mgr.conf file"
