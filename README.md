# backup-scripts
Set of backup scripts for different purposes. These scripts are written in a way to run them inside a small, light-weight Alpine Linux container (e.g. on a OpenWRT router).

# Installation

1. Install these packages (on Alpine Linux):
```apk add lua5.2 lua5.2-penlight git ```

1. Then git clone this repository

1. Make sure that the user account running the script can ssh into the server without entering a password.

1. Run the scripts

# Usage

## backup-git
Backing up git repositories is easy, as only a clone/fetch operation is required. To automate this, this script will clone/fetche **ALL** git repositories in the \<source_dir\> on the server to the local \<target_dir\>.

```
Backup remote git repositories by cloning/fetching
  -p, --port    (default 22)  ssh port on remote server
  <server>      (string)  server to be backed up
  <source_dir>  (string)  absolute path to git repos on server
  <target_dir>  (string)  absolute path where to store the backups locally
```


# License

Unless explicitly stated otherwise all files in this repository are licensed under the Apache Software License 2.0.
