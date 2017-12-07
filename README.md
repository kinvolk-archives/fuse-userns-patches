# Kernel patches for non-init user namespace on FUSE filesystem

## How to apply

```
$ git clone git@github.com:kinvolk/fuse-userns-patches.git

$ git clone https://kernel.googlesource.com/pub/scm/linux/kernel/git/stable/linux-stable
$ pushd linux-stable
$ git checkout v4.15-rc1
$ git am ../fuse-userns-patches/patches/00*.patch
```

## Cover letter

Cover letter is available in plain text: [./COVER_LETTER.txt](./COVER_LETTER.txt)
