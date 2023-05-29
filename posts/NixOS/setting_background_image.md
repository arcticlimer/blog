---
date: 2021-10-30
title: Setting XServer's Background Image
---

If you have NixOS managing your XServer's session you can easily set your
desktop background image by moving an image to `~/.background-image`. If you
want to customize it furthermore, you can check the options available in the
`services.xserver.desktopManager.wallpaper` namespace.

# Resources
- `man configuration.nix`
