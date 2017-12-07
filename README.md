# Kernel patches for non-init user namespace on FUSE filesystem

## How to apply

```
$ git clone git@github.com:kinvolk/fuse-userns-patches.git

$ git clone https://kernel.googlesource.com/pub/scm/linux/kernel/git/stable/linux-stable
$ pushd linux-stable
$ git checkout v4.15-rc1
$ git am ../fuse-userns-patches/patches/00*.patch
```

## How to send patches to kernel mailing lists

Let's assume that the all the required configurations are done in git config,
and all the recipients are correctly set in individual patches as well.


```
$ git send-email \
  --subject="non-init user namespace for FUSE" \
  --thread \
  --from="Dongsu Park <dongsu@kinvolk.io>" \
  --to=linux-kernel@vger.kernel.org \
  --cc="Alban Crequy <alban@kinvolk.io>" \
  --cc="Dongsu Park <dongsu@kinvolk.io>" \
  --cc="Eric W. Biederman <ebiederm@xmission.com>" \
  --cc="Sargun Dhillon <sargun@sargun.me>" \
  --cc="Seth Forshee <seth.forshee@canonical.com>" \
  --cc="Fabio Kung <fabio.kung@gmail.com>" \
  --bcc="Dongsu Park <dongsu@kinvolk.io>" \
  patches/00*.patch
```

## Cover letter

Cover letter is available: [./patches/0000-cover-letter.patch](./patches/0000-cover-letter.patch)
