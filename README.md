# backup-scripts
Set of backup scripts for different purposes. These scripts are written in a 
way to run them inside a small, light-weight Alpine Linux container (e.g. 
on a OpenWRT router).

# Installation

1. Install these packages (on Alpine Linux):
```apk add lua5.2 lua5.2-penlight git rsync```

1. To use the webdav-backup, see [davfs2](doc/davfs2.md)

1. Then git clone this repository

1. Make sure that the user account running the script can ssh into the server 
without entering a password.

1. Run the scripts

# Usage

## backup-git
Backing up git repositories is easy, as only a clone/fetch operation is required. 
To automate this, this script will clone/fetch **ALL** git repositories in the 
\<source_dir\> on the server to the local \<target_dir\>.

```
Backup remote git repositories by cloning/fetching
  -p, --port    (default 22)  ssh port on remote server
  <server>      (string)  server to be backed up
  <source_dir>  (string)  absolute path to git repos on server
  <target_dir>  (string)  absolute path where to store the backups locally
```

## backup-files
Files are backed-up file-by-file using rsync. For each call a new sub-folder 
with the current timestamp will be created. To reduce disc usage and data 
transfer, rsync is used with --link-dest parameter. This will rsync to create
hard links for unchanged files.

```
Create a rsync diffential backup
<source_url>   (string)  rsync source url to be backed up
<target_root>   (string)  Target path, where backups will be stores
```

## backup-webdav
TODO: implement this

## backup-prune
TODO: Implement to thin out the incremental backups to reduce the disc usage.

## running from a lua script
You can also run the backup commands from a lua script. Example:
```
#!/usr/bin/lua5.2

package.path = package.path..(';<path of git repo clone>/?/init.lua')
local backup = require('backup')

-- to backup a git repo:
backup.git('hostname',22,'/home/git','/home/backup/git')

-- to backup some files:
backup.files('hostname:/home/someuser/important','/home/backup/important')
```

# License

Unless explicitly stated otherwise all files in this repository are licensed under the Apache Software License 2.0.
