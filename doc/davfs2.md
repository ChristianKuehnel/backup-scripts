# davfs2 setup
Setting up davfs on Alpine Linux in a LXC container

## configure the container
1. davfs2 uses fuse to mount the webdav folder. And fuse needs /dev/fuse. So wee need to allow the container to access /dev/fuse. To do so, you have to add these lines to the config file of your container:

```
# fuse
lxc.cgroup.devices.allow = c 10:229 rwm
lxc.mount.entry = /dev/fuse /dev/fuse  none bind,optional,create=dir
```  

## inside the container
1. Install fuse and sudo:
```
apk add fuse sudo
```
Note: sudo is only required if you plan to run the scripts as non-root user

1. add your local user account to the group davfs2
```
addgroup <username> davfs2
```


1. add two lines to /etc/sudoers
```
%davfs2 ALL = NOPASSWD: /bin/mount
%davfs2 ALL = NOPASSWD: /bin/umount
```


1. Install the package davfs2, which is 
only available in edge. Download davfs2-<versionnumber>.apk from the
[package repository](http://dl-cdn.alpinelinux.org/alpine/edge/community/) and install it manually wtih ```apk add <package>```.

1. create ```/dev/init.d/lxc-devices``` with this content:

```
#!/sbin/openrc-run

depend(){
	provide lxc_devices
}

start() {
	ebegin "creating devices for container"
	if [ ! -c /dev/fuse ] 
	then
		mknod /dev/fuse c 10 229
	fi
	eend $?
}
```

1. make lxc-devices executable and run it:
```
chmod +x /etc/init.d/lxc-devices
/etc/init.d/lxc-devices start
```

1. create a directory to mount the webdav folder
```
mkdir /mnt/webdav
```

1. add this line to your ```/etc/fstab```:
```
https://<path-to-webdav>/ /mnt/webdav davfs user,auto,_netdev 0 0 
```

for NextCloud use:
```
https://<hostname>/nextcloud/remote.php/dav/files/<username>/ /mnt/webdav davfs user,auto,_netdev 0 0 
```

1. add a line with the credentials to /etc/davfs2/secrets, where you give the local mount point from fstab:
```
/mnt/webdav <username> <password>
```




1. Test your setup by mounting the foler:
```
mount /mnt/webdav
```

