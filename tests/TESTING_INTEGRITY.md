## Testing Integrity Measurement Architecture

This document describes how to test IMA (Integrity Measurement Architecture).
Although the patchset for FUSE user namespaces is not exactly related to IMA,
its change could cause side effects w.r.t security and integrity. Therefore
we need to test IMA.


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

FYI, as for `ima_policy`, you can choose either `tcb`, `appraise_tcb`, or `secure_boot`.
Actually `tcb` is recommended.

Optionally, you might need to remount rootfs with `iversion`. (not `i_version`)

```
sudo mount -o remount,rw,iversion /
```

### Look into securityfs

Look into IMA data under sysfs.

```
(Optional) mount -t securityfs securityfs /sys/kernel/security
ls -l /sys/kernel/security/ima
cat /sys/kernel/security/ima/ascii_runtime_measurements
```

Then you can see integrity data such as hash for each file, which has been
executed by the root user. Try to copy a file to FUSE-mounted filesystem,
and run it from there.

```
cp /bin/bash /mnt/memfs/bash2
/mnt/memfs/bash2 -c "echo hello"
grep bash2 /sys/kernel/security/ima/ascii_runtime_measurements
```

### Test with memfs

We patched memfs to be able to test xattr `security.ima`.

```
git clone https://github.com/kinvolk/memfs
cd memfs
git checkout alban/faking_xattr
go build -o $GOPATH/bin/memfs github.com/bbengfort/memfs/cmd
sudo mkdir -p /mnt/memfs
sudo memfs /mnt/memfs
touch /mnt/memfs/INJECT_XATTR_security.ima=HelloEveryone
getfattr -n security.ima /mnt/memfs/INJECT_XATTR_security.ima=Hello
Result: security.ima="HelloEveryone"
```

### Remeasuring hashes automatically

Make sure that rootfs is mounted with `iversion` option. Run:

```
getfattr -m ^security --dump -e hex /bin/bzcat
```

In the beginning, it will not show its `security.ima` xattr value.
That's because the xattr value is measured only after the file
was once executed. So run the file like this:

```
bzcat -h &> /dev/null
getfattr -m ^security --dump -e hex /bin/bzcat
```

Now it should show its `security.ima` value.

### (optional) Testing the force option for the IMA policy

Build the kernel from our custom branch:
https://github.com/kinvolk/linux/tree/dongsu/fuse-userns-v5-2
This branch consists of experimental patches like `"ima: define a new policy
option named force"` as well as other dependencies. (NOTE: when the mainline
kernel merged the integrity-next tree in the future, this branch might need
to be updated too.)

Please make sure that the kernel is compiled with
`CONFIG_IMA_APPRAISE_SIGNED_INIT=y`. Without this option, kernel cannot
accept the force option at all.

```
mkdir --parent /etc/ima
cat /sys/kernel/security/ima/policy > /etc/ima/ima-policy
```

Update the local policy file as you want, to enable the `force` option,
for example:

```
echo "measure force" >> /etc/ima/ima-policy
```

Make the kernel load the new policy file.

```
echo "/etc/ima/ima-policy" > /sys/kernel/security/ima/policy
```

Doing this, the kernel should be able to load policies listed in
`/etc/ima/ima-policy`, without any error. The loaded policies can be seen by
reading the sysfs file again.

```
cat /sys/kernel/security/ima/policy

```

If systemd with IMA feature is running on your system, then the local IMA
policy will be automatically loaded during the next boots.

