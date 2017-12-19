## build kernel from the fuse-userns branch

```
$ git clone https://github.com/kinvolk/linux kinvolk-linux
$ cd kinvolk-linux
$ git checkout dongsu/fuse-userns-v5-1
$ curl -s -o .config https://raw.githubusercontent.com/kinvolk/linux/dongsu/test-fuse-userns/config
$ yes "" | make oldconfig
$ make
$ sudo make modules_install install
( reboot the system )
```

## How to test FUSE mounts from non-init user namespaces

Let me describe how to test mounting from non-init user namespaces. It's
assumed that tests are done via sshfs, a userspace filesystem based on
FUSE with ssh as backend. Testing system is Fedora 27.

```
$ sudo dnf install -y sshfs
$ sudo mkdir -p /mnt/userns
```

As a workaround to get the sshfs permission checks, do it:

```
$ sudo chown -R $UID:$UID /etc/ssh/ssh_config.d /usr/share/crypto-policies

$ unshare -U -r -m
# sshfs root@localhost: /mnt/userns
```

You can see sshfs being mounted from a non-init user namespace.

```
# mount | grep sshfs
root@localhost: on /mnt/userns type fuse.sshfs
(rw,nosuid,nodev,relatime,user_id=0,group_id=0)

# touch /mnt/userns/test
# ls -l /mnt/userns/test
-rw-r--r-- 1 root root 0 Dec 11 19:01 /mnt/userns/test
```

Open another terminal, check the mountpoint from outside the namespace.

```
$ grep userns /proc/$(pidof sshfs)/mountinfo
131 102 0:35 / /mnt/userns rw,nosuid,nodev,relatime - fuse.sshfs
root@localhost: rw,user_id=0,group_id=0
```

After all tests are done, you can unmount the filesystem
inside the namespace.

```
# fusermount -u /mnt/userns
```

