# Another bash script to manage an apt repo

## Installation
The script can be installed from berbascum's git apt repo
sudo wget -o /usr/share/keyrings/berb-apt.gpg  https://github.com/berbascum/berb-apt-git-repo/raw/main/berb-apt.gpg
sudo wget -o /etc/apt/sources.list.d//berb-apt.list  https://github.com/berbascum/berb-apt-git-repo/raw/main/berb-apt.list


## Help
This script can be runned from any dir in PATH

Change to the apt repo dir is needed first

The files \"key-ids.conf\" and \"apt-repo.conf\" in /usr/share/berb-apt-mgr need to be configured and moved to the apt repo rootdir

To create the initial dir structure, run the script with --mkdirs tag

To rebuild repo, run the script with --rebuild tag
