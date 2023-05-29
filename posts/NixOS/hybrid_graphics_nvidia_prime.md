---
date: 2021-10-27
title: Hybrid Graphics with NVIDIA PRIME
---

# Table of Contents
<!-- toc -->

# Intro
I've spent some time trying to setup hybrid graphics on NixOS and managed to get
it up and running after adapting some of the content available at the NixOS Wiki.
This post will go through the necessary changes that I had to do in order to get
it working.

## Author's Setup
The relevant setup for this post includes:
- OS: `NixOS 21.11 Porcupine`
- CPU: `Intel i7-7700`
- GPU: `NVIDIA GTX 1070`
- iGPU: `Intel HD Graphics 630`

> Note: I have not tested this in other machines, maybe some changes will be
> necessary for this to run in other kinds of hardware.

# NixOS Configuration
Below is the necessary NixOS configuration to get it up and running. The
relevant parts will be covered next.

```nix
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$1" "$@"
  '';
in
{
  environment.systemPackages = [
    nvidia-offload
  ];

  services.xserver.config = ''
    # Integrated Intel GPU
    Section "Device"
      Identifier "iGPU"
      Driver "modesetting"
    EndSection

    # Dedicated NVIDIA GPU
    Section "Device"
      Identifier "dGPU"
      Driver "nvidia"
    EndSection

    Section "ServerLayout"
      Identifier "layout"
      Screen 0 "iGPU"
    EndSection

    Section "Screen"
      Identifier "iGPU"
      Device "iGPU"
    EndSection
  '';

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.prime = {
    offload.enable = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}
```

## Offload Script
```nix
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$1" "$@"
  '';
in
{
  environment.systemPackages = [
    nvidia-offload
  ];
}
```

This defines a small helper script that you will be using when you want to launch a program using the dedicated GPU.

### Examples
- Launching glxgears using the integrated GPU: `glxgears`
- Launching glxgears using the dedicated GPU: `nvidia-offload glxgears`

> Extra: Launch Steam games using the GPU:
> - Go at the game properties inside the Steam client
> - Find `Launch Options`
> - If it's empty, change it to `nvidia-offload %command%`

## XServer Configuration

```nix
services.xserver.config = ''
  # Integrated Intel GPU
  Section "Device"
    Identifier "iGPU"
    Driver "modesetting"
  EndSection

  # Dedicated NVIDIA GPU
  Section "Device"
    Identifier "dGPU"
    Driver "nvidia"
  EndSection

  Section "ServerLayout"
    Identifier "layout"
    Screen 0 "iGPU"
  EndSection

  Section "Screen"
    Identifier "iGPU"
    Device "iGPU"
  EndSection
'';
```

This was necessary for me because the XServer was not recognizing
my graphics card, adding this extra piece of configuration solved it.

## NVIDIA + PRIME Configuration

```nix
services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia.prime = {
  offload.enable = true;
  intelBusId = "PCI:0:2:0";
  nvidiaBusId = "PCI:1:0:0";
};
```

The first line here enables the **proprietary NVIDIA drivers** in our system, this
line is very important, otherwise it will not work.

Below is the NVIDIA PRIME configuration, in which we must enable `offload` and
the both the `nvidiaBusId` and `intelBusId` of our GPUs. You can find out how to
get the bus ids by reading this [relevant part of the NixOS Wiki](https://nixos.wiki/wiki/Nvidia#lspci).

> Note: In my system, I had to go to my BIOS settings and change the default
> display output to `IGFX` (Integrated Graphics) instead of directly using the
> PCIE slot, otherwise my system wouldn't detect the Intel HD device.

# Conclusion
After some tries I could get hybrid graphics working on NixOS in a quite easy
and reproducible way. This is a writeup meant to help other people with the same
issue and remember myself about it if I ever need to change it again.

# Resources
- [NixOS Wiki's NVIDIA page](https://nixos.wiki/wiki/Nvidia)
- [NVIDIA's PRIME Offloading](https://download.nvidia.com/XFree86/Linux-x86_64/435.17/README/primerenderoffload.html)
