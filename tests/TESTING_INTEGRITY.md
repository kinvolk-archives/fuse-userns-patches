## Testing Integrity Measurement Architecture

This document describes how to test IMA (Integrity Measurement Architecture).
Although the patchset for FUSE user namespaces is not exactly related to IMA,
its change could cause side effects w.r.t security and integrity. There are
a couple of solutions suggested for addressing potential security issues.
For example, adding a `force` option to IMA, as well as making FUSE discard
cached results.

That's why we need to test IMA.


## How to test IMA

### Prepare custom kernel

Recompile the kernel with the config options `CONFIG_IMA` as well as `CONFIG_EVM`,
as these are not enabled in the default kernel config file. You can simply download
our minimized kernel config from
https://raw.githubusercontent.com/kinvolk/linux/dongsu/test-fuse-userns/config .

Add an additional boot command line parameter like this,

```
ima_policy=tcb ima_appraise_tcb ima_appraise=fix rootflags=i_version evm=fix
```

and reboot the kernel.

As for `ima_policy`, you can choose either `tcb`, `appraise_tcb`, or `secure_boot`.
Actually `tcb` is recommended.

Note that instead of `ima_policy=tcb`, you can also set `ima_tcb`, which is
though a deprecated option.

Optionally, you might need to remount rootfs with `iversion`. (not `i_version`)

```
# mount -o remount,rw,iversion /
```

### Look into securityfs

Look into IMA data under sysfs.

```
### (optional) mount -t securityfs securityfs /sys/kernel/security
$ ls -l /sys/kernel/security/ima
$ sudo cat /sys/kernel/security/ima/ascii_runtime_measurements
```

Then you can see integrity data such as hash for each file, which has been
executed by the root user. Try to copy a file to a filesystem,
and run it from there.

```
$ cp /bin/bash /bin/bash2
$ /bin/bash2 -c "echo hello"
$ grep bash2 /sys/kernel/security/ima/ascii_runtime_measurements
```

### Remeasuring hashes automatically

This section explains a test based on rootfs with ext4 filesystem.
Make sure that rootfs is mounted with `i_version` option.


```
$ mount -t ext4
/dev/sda1 on / type ext4 (rw,relatime,i_version,data=ordered)
```

Try running any executable under the rootfs, e.g.:

```
$ cp /bin/bash /bin/bash2
$ getfattr -m ^security --dump -e hex /bin/bash2
```

In the beginning, it will not show its correct `security.ima` xattr value.
That's because the xattr value is measured only after the file was once
executed. So run the executable file, e.g `/bin/bash2 -h`, or simply get the
hash recalculated like this:

```
$ evmctl ima_hash /bin/bash2
$ getfattr -m ^security --dump -e hex /bin/bash2
```

Now it should show its correct `security.ima` value.

### (optional) Testing with memfs

We patched [memfs](https://github.com/bbengfort/memfs) to be able to test
xattr `security.ima`, by setting an arbitrary key/value pair. (This might
not be a generic way to test IMA) Note that since memfs/fuse does not
support the `i_version` mount option, the automatic hash update method as
used in ext4 will not be available for memfs.

```
$ git clone https://github.com/kinvolk/memfs
$ cd memfs
$ git checkout alban/faking_xattr
$ go build -o $GOPATH/bin/memfs github.com/bbengfort/memfs/cmd
$ sudo mkdir -p /mnt/memfs
$ sudo ~/go/bin/memfs /mnt/memfs
$ touch /mnt/memfs/INJECT_XATTR_security.ima=HelloEveryone
$ getfattr -n security.ima /mnt/memfs/INJECT_XATTR_security.ima=Hello
Result: security.ima="HelloEveryone"
```

### (optional) Testing the force option for the IMA policy

Build the kernel from our custom branch:
https://github.com/kinvolk/linux/tree/dongsu/fuse-userns-v5-2
This branch consists of experimental patches like [`ima: define a new policy
option named force`](https://marc.info/?l=linux-integrity&m=151275680115856&w=2)
as well as other dependencies. (NOTE: when the mainline kernel merged the
[next-integrity](https://kernel.googlesource.com/pub/scm/linux/kernel/git/zohar/linux-integrity/+/next-integrity) tree in the future, this branch might need to be updated too.)

Please make sure that the kernel is compiled with
`CONFIG_IMA_APPRAISE_SIGNED_INIT=y`. Without this option, kernel cannot
accept the force option at all. Now store in-kernel policies into a local
file `/etc/ima/ima-policy`.

```
$ mkdir --parent /etc/ima
$ sudo cat /sys/kernel/security/ima/policy > /etc/ima/ima-policy
```

Update the local policy file as you want, to enable the `force` option,
for example:

```
$ echo "measure force" >> /etc/ima/ima-policy
```

Make the kernel load the new policy file.

```
$ echo "/etc/ima/ima-policy" > /sys/kernel/security/ima/policy
```

Doing this, the kernel should be able to load policies listed in
`/etc/ima/ima-policy`, without any error. The loaded policies can be seen by
reading the sysfs file again.

```
$ sudo cat /sys/kernel/security/ima/policy

```

If systemd with IMA feature is running on your system, then the local IMA
policy will be automatically loaded during the next boots.


## (optional) How to generally test Linux Kernel

One of the standard kernel testing tools is
[LTP (Linux Test Project)](https://github.com/linux-test-project/ltp),
which already includes basic testing tools in userspace. It includes tools for
Linux namespaces as well. We can make use of LTP for running regression tests.

```
$ git clone https://github.com/linux-test-project/ltp.git
$ cd ltp
$ ./configure && make && sudo make install
$ cd /opt/ltp
$ sudo ./runltp -f containers
$ sudo ./runltp -f fs
```

Then container-/fs-related tests in LTP will run. Let's make sure that all
tests pass.

NOTE: IMA tests in LTP don't seem to work correctly with recent kernels.
So it's not expected that `./runltp -f ima` passes in general.
