# Another bash script to manage an apt repo
Simple bash script to manage a configurable multiarch and multirelease apt repository

### Fetures
- Multi-component
- Multiarch
- Multi-release
- APT repo directory tree creation (--mkdirs flag)
- Config files for apt-ftparchive creation (--createconf flag)
- Packages creation per release and arch (--rebuild)
- Release creation per release and arch (--rebuild)
- Release and InRelease signing (--rebuild)
- Pub gpg keyring exportation (--rebuild)
- Repo sources.list creation
- After generating a new dir tree and createconfig,  run with --rebuild to regenerate all
- After adding new packages to any pool, run with --rebuild to regenerate all

### version 2.0.4.1-stable
- New: local config file auto-installation .(but need to be configured manually)
- New: key-ids.conf file auto-installation.
- New: Additional checks to do more easy the initial configuration.

### version 2.0.3.1-stable
- Fix: multi-release feature.
- New: on --rebuild feature, ask for a extra commit info before committing the rebuild changes.

### version 2.0.2.1-stable
- Broken: multi-release feature

## Installation from apt repo (recomended way)
* It's the recomended way since some depends relies on the debian package management.

* Visit [Berbascum's apt repo url](https://github.com/berbascum/berb-apt-git-repo) to add the apt repo

* Install the pachage from apt
```
sudo apt-get install berb-apt-mgr
```

## Help
* The gpg key to use should be previously installed on the user's gnupg dir

* script tags:

  --mkdirs:     Creates the repo dir structure, based on the releases and archs"
                configured in the berb-apt-mgr.conf file"

  --rebuild:    Rebuilds the repo"

  --createconf: Generates the aptftp.conf and aptgenerate.conf files from"
                temples using the releases and archs configured in the"
                berb-apt-mgr.conf file"

                Implies interactive optional --mkdirs
                
