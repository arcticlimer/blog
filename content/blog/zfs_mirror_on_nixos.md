---
date: 2022-09-13
title: Setting ZFS mirrors up in NixOS
---

## ZFS

ZFS is a modern file system that works with pool of different devices and allows
for redudancy, efficient snapshots, compression and deduplication.

## Setup

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

# Use cfdisk or some other tool to partition your disks.
# In my case I've created the following partition table in both disks:
# 100M BIOS Boot
# 4G Linux Swap
# Remaining space ZFS
cfdisk $DISK_ONE
cfdisk $DISK_TWO

zpool create -O mountpoint=none -O compression=lz4 $POOL_NAME mirror $DISK_ONE-part3 $DISK_TWO-part3
zfs create -o mountpoint=legacy $POOL_NAME/$DATASET_NAME

mkfs.vfat $DISK_ONE-part1
mkfs.vfat $DISK_TWO-part1

# Activate only one of these using `swapon`
mkswap $DISK_ONE-part2
mkswap $DISK_TWO-part2

swapon $DISK_ONE-part2

mount -t zfs $POOL_NAME/$DATASET_NAME /mnt
nixos-generate-config --root /mnt

# Tweak your configurations and install NixOS
nixos-install
```

In order to setup two boot partitions in NixOs, use the
`boot.loader.grub.devices` attribute:

```nix
boot.loader.grub.devices = [ "/dev/sda" "/dev/sdb" ];
```

Now if one of the disks die you will still be able to boot into your system.

## Replacing devices

Just a few days after doing the first installation, one of the hard drives being
used died. It was surprisingly easy to repair my mirror using some ZFS magic.

```
[root@nixos:~]# zpool status
  pool: main
 state: DEGRADED
status: One or more devices could not be used because the label is missing or
        invalid.  Sufficient replicas exist for the pool to continue
        functioning in a degraded state.
action: Replace the device using 'zpool replace'.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-4J
config:

        NAME                              STATE     READ WRITE CKSUM
        main                              DEGRADED     0     0     0
          mirror-0                        DEGRADED     0     0     0
            <device_id>                   UNAVAIL      0     0     0  was /dev/disk/by-id/wwn-0x5000c5007b582f48-part3
            wwn-0x5000c50074fbe272-part3  ONLINE       0     0     0
```


In order to repair a pool, run the following command:
```sh
zpool replace <pool> <device_id> <new_device_path>
```
Then ZFS will start the resilvering process and your mirror will be ready again
some time later.

## Samba

Samba allows the server to be easily usable from both Windows and Linux clients.

```nix
services.samba = {
  enable = true;
  extraConfig = ''
    hosts allow = 192.168.1. 127.0.0.1 localhost
  '';
  shares = {
    samba = {
      path = "/home/vini/smb";
      "read only" = "no";
    };
  };
};
```

> For some reason, samba gives "read only drive" errors if the share and
> directory name are the same.

Register a samba user:
```sh
smbpasswd -a <samba_user>
```

Now whenever you need to access your files, just log in using this user.


