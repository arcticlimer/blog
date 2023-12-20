---
date: 2022-09-18
title: Recovering from broken bootloader
categories:
- NixOS
---

NixOS provides some really nice properties, such as the ability to rollback your
config using a menu in the bootloader if you need. But what if there is no
bootloader? Recently the power went off when `nixos-rebuild switch` was
rebuilding the bootloader and I got locked out of my PC.

In order to repair that, there is no big secret: you will need just a live NixOS
USB. Then just mount your partitions and run from the ISO: `nixos-install
--flake <path_to_your_config>`, then Nix will already notice that all the
required packages are already in your nix store and will just fix your
bootloader.

