---
date: 2022-07-24T19:52
title: Installing Armbian into an old TV Box
---

Recently I've found a rather old unused TV Box and decided to install Armbian in
it to power my homelab (or roomlab, actually).

The box that I have here is a Nexbox A95X. [This video](https://www.youtube.com/watch?v=F2xv7kPNeEU)
explains pretty much well what you should do in order to install Armbian on
yours. But I ran into some problems when trying it in my **A95X-B7N** model:
- In the video, when the `extlinux/extlinux.conf` file is being edited, I had to
  uncomment the `meson-gxl-s905x-p212.dtb` instead of the `meson-gxm-q200.dtb`
  FTD directive.
- Wi-Fi is not working. From the video comments, it appears that installing
  other versions than *bullseye* might make Wi-Fi work.

# Resources
- [Armbian images](https://users.armbian.com/balbes150/arm-64/)

