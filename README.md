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

## Installation from apt repo
The script can be installed from [berbascum's git apt repo](https://github.com/berbascum/berb-apt-git-repo)


## Installation cloning the repo
* Clone the repo from Github and cd to it
```
git clone https://github.com/berbascum/berb-apt-mgr.git && cd berb-apt-mgr
```

* Copy the app files
```
sudo mkdir /etc/berb-apt-mgr /usr/share/berb-apt-mgr
```
```
sudo cp ./pkg_rootfs/usr/bin/berb-apt-mgr /usr/bin
```
```
sudo cp ./pkg_rootfs/etc/berb-apt-mgr/berb-apt-mgr-main.conf /etc/berb-apt-mgr/                   
```
```
sudo cp ./pkg_rootfs/usr/share/berb-apt-mgr/* /usr/share//berb-apt-mgr/
```
```
sudo cp ./pkg_rootfs/usr/share/berb-apt-mgr/* /usr/share//berb-apt-mgr/
```

* Create the local berb-apt-mgr conf file and configure it
```
sudo cp /usr/share/berb-apt-mgr/berb-apt-mgr_template.conf /path/to/apt/repo/berb-apt-mgr.conf
```

* The files "key-ids.conf" /usr/share/berb-apt-mgr need to be configured and moved to the apt repo rootdir
```
cp /usrr/share/berb-apt-mgr/key-ids.conf /path/to/apt/repo/
```

## Help
* script tags:

  --mkdirs:     Creates the repo dir structure, based on the releases and archs"
                configured in the berb-apt-mgr.conf file"

  --rebuild:    Rebuilds the repo"

  --createconf: Generates the aptftp.conf and aptgenerate.conf files from"
                temples using the releases and archs configured in the"
                berb-apt-mgr.conf file"
