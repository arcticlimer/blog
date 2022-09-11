---
date: 2022-09-7T16:32
title: Setting ZFS mirrors up in NixOS
draft: true
---

> TODO: Brief explanation about how zfs works and its main concepts

> Warning: When experimenting with different partitioning schemas, if you happen
> to create any pool or dataset using `zpool create` or `zfs create`, remember
> to delete them before using the proper pool and dataset deletion commands before
> repartitioning, otherwise you will get stuck with "phantom" ZFS pools that will
> be very annoying to remove.

```sh
POOL_NAME=main
DATASET_NAME=root
DISK_ONE=disk_one_path
DISK_TWO=disk_two_path

# talk about the partitions that I needed to create in my case

zpool create -O mountpoint=none -O compression=lz4 $POOL_NAME mirror $DISK_ONE-part3 $DISK_TWO-part3
zfs create -o mountpoint=legacy $POOL_NAME/$DATASET_NAME

mkfs.vfat $DISK_ONE-part1
mkfs.vfat $DISK_TWO-part1

# Activate only one of these using `swapon`
mkswap $DISK_ONE-part2
mkswap $DISK_TWO-part2
```

> TODO: Talk about configuring samba
