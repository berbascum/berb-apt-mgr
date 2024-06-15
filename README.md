# Another bash script to manage an apt repo
Simple bash script to manage a configurable multiarch and multirelease apt repository

## Installation
The script can be installed from berbascum's git apt repo
sudo wget -o /usr/share/keyrings/berb-apt.gpg  https://github.com/berbascum/berb-apt-git-repo/raw/main/berb-apt.gpg
sudo wget -o /etc/apt/sources.list.d//berb-apt.list  https://github.com/berbascum/berb-apt-git-repo/raw/main/berb-apt.list

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
