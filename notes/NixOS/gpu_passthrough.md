---
date: 2021-10-29T21:01
title: KVM GPU Passthrough
---

# Table of Contents
<!-- toc -->

# Intro
Recently I wanted to run a Windows virtual machine from NixOS that has access to
my GPU, mostly for gaming. This post will cover from enabling the necessary
kernel options and crafting a NixOS configuration to setting a Windows VM up and
making it able to use the GPU and other peripherals.

> Note: This post is heavily based in [this Arch Wiki article](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF) and is made
> mostly as a guide to the author itself, although it is supposed to help any
> people with a similar hardware setup trying to GPU passthrough on NixOS.

# Hardware
This is my relevant hardware information for this post. It's worth noting that I
only have **one dedicated GPU** and **one integrated GPU**. This post is mainly
meant for people in that same situation.

- OS: `NixOS 21.11 Porcupine`
- Motherboard: `GA-Gaming B8`
- CPU: `Intel i7-7700`
- Dedicated GPU: `NVIDIA GTX 1070`
- Integrated GPU: `Intel HD Graphics 630`

# Requirements
- You must have the `VT-D` feature enabled inside your BIOS
- [Your hardware must support IOMMU](https://en.wikipedia.org/wiki/List_of_IOMMU-supporting_hardware)
- You must have a spare GPU device.

# Setup

## Isolating the GPU
In this section we will isolate the graphics card from the host so that we can
pass it through without any issues.
> Note: This section assumes that you are going to passthrough a NVDIA GPU.

### Setting Integrated Graphics as Output
> Note: This section is only valid if you only have only one **GPU** and one
> **iGPU**.

In order to make it work, you will have to go to your **BIOS** settings and change
the default output display to the integrated graphics.

> Caution: Be sure that you have a way to set the graphics output of your
> motherboard as the input to your monitor, otherwise you will be locked without
> graphics.

### Enabling IOMMU
Inside your NixOS configuration, add:
```nix
boot.kernelParams = [
  # https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_IOMMU
  "intel_iommu=on"
  "iommu=pt"

  # You might need this to avoid ASPM errors on boot
  "pcie_aspm=off"
];
```
Then rebuild and reboot your system.

### Identifying IOMMU Devices
You can use the following snippet to identify your IOMMU devices:
```sh
shopt -s nullglob
for d in /sys/kernel/iommu_groups/*/devices/*; do
    n=''${d#*/iommu_groups/*}; n=''${n%%/*}
    printf "IOMMU Group %s " "$n"
    lspci -nns "''${d##*/}"
done;
```
> Note: This script requires the `lspci` binary, available on Nix via the
> `pciutils` package.

This will be useful to get the ID of the graphics card in the next section.
Output example:
```sh
❯ list-iommu-devices  | grep GTX
IOMMU Group 1 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP104 [GeForce GTX 1070] [10de:1b81] (rev a1)
```

### Configuring the NixOS Host
Add the following to your NixOS configuration:

```nix
# Enable VFIO and KVM kernel modules
boot.kernelModules = [
  "kvm-intel" # If using an AMD processor, use `kvm-amd`
  "vfio_pci"
  "vfio_iommu_type1"
  "vfio_virqfd"
  "vfio"
];

# We blacklist NVIDIA drivers from the kernel modules, ensuring the GPU
# doesn't get loaded.
boot.blacklistedKernelModules = [
  "nvidia"
  "nouveau"
];

# Change the id below after `ids=` to the same of your GPU id
boot.extraModprobeConfig = "options vfio-pci ids=10de:1b81";

# This might be necessary for you
boot.postBootCommands = ''
  DEVS="0000:0f:00.0 0000:0f:00.1"
  for DEV in $DEVS; do
    echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  done
  modprobe -i vfio-pci
'';
```

Now rebuild your configuration and reboot. You can test that the configuration
worked by running the following:
```bash
❯ dmesg | grep -i vfio
[    2.382403] VFIO - User Level meta-driver version: 0.3
[    2.391945] vfio-pci 0000:01:00.0: vgaarb: changed VGA decodes: olddecodes=io+mem,decodes=io+mem:owns=none
[    2.403383] vfio_pci: add [10de:1b81[ffffffff:ffffffff]] class 0x000000/00000000
[    2.798115] vfio-pci 0000:01:00.0: vgaarb: changed VGA decodes: olddecodes=io+mem,decodes=io+mem:owns=none
[  552.633505] vfio-pci 0000:01:00.0: enabling device (0000 -> 0003)
[  552.633809] vfio-pci 0000:01:00.0: vfio_ecap_init: hiding ecap 0x19@0x900
[ 1034.204707] vfio-pci 0000:01:00.0: vfio_ecap_init: hiding ecap 0x19@0x900
```
The output should be similar to this (note the `add [10de:1b81...` line).

## Installing the Guest OS

### NixOS Virtualization Setup
```nix
virtualisation.libvirtd = {
  enable = true;
  onBoot = "ignore";
  onShutdown = "shutdown";
  qemu = {
    ovmf.enable = true;
    runAsRoot = false;
  };
};

environment.systemPackages = with pkgs; [
  virt-manager
];
```


### Installation
> This part assumes you are going to install Windows inside the box.
- Download the Windows ISO of your liking (This post was tested using Windows 10).
- Move the ISO to `/var/lib/libvirt/images` so that we don't get permission
  errors when launching the VM.
- Open the `virt-manager` program.
- Create the VM normally until the Wizard asks you to set the guest name, then
  check **Customize before install** and proceed.
- Inside the **Overview** section, change firmware to **UEFI**.
- Inside the **CPUs** section, change the CPU model to **host-passthrough** (if it's
  not being shown uncheck **Copy host CPU configuration**).
- Don't add the PCI device yet, just start the Windows ISO and install it
  through the `virt-viewer` screen.
- After a successful installation, shut down the box and proceed.

> Note: If you fall inside an "UEFI Shell" when starting the VM for
> installation, just type exit, navigate to **Boot Manager** and boot into the
> desired device.

## PCI Passthrough

- Remove these virtual device sections in box's the XML config:
  ```xml
  <channel type="spicevmc">
    ...
  </channel>
  <input type="tablet" bus="usb">
    ...
  </input>
  <input type="mouse" bus="ps2"/>
  <input type="keyboard" bus="ps2"/>
  <graphics type="spice" autoport="yes">
    ...
  </graphics>
  <video>
    <model type="qxl" .../>
    ...
  </video>
  ```
- Add this to avoid virtualization detection:
  ```xml
  <features>
    <hyperv>
      <vendor_id state='on' value='randomid'/>
    </hyperv>
  </features>
  ```
  ```xml
  <features>
    <kvm>
      <hidden state='on'/>
    </kvm>
  </features>
  ```
  Depending on your card, the GPU might detect it's being virtualized and refuse
  to run, triggering an `error 43` (device unidentifiable) and leading to a
  boring black screen. These snippets help to avoid this problem.

- In the box's details, click **Add Hardware**.
- Add all the devices that are in the same [**IOMMU**](#enabling-iommu) group of your GPU.
- You should now be able to start your box and change your monitor input to the
  GPU output to check if it's working. You should see your Windows box normally
  on your screen.

## Keyboard/Mouse support
Add to your box configuration, inside the `<devices>` section:
```xml
<input type="evdev">
  <source dev="/dev/input/by-id/your-mouse-here" />
</input>
<input type="evdev">
  <source dev="/dev/input/by-id/your-keyboard-here" grab="all" repeat="on"/>
</input>
<input type="mouse" bus="virtio" />
<input type="keyboard" bus="virtio" />
```

### Tips
- The devices must have "event" in their name.
- To check whether a device is the correct, `cat` it and use the device, you
  should see some gibberish being printed into the shell that `cat` is
  running.

After setting this up, you should now be able to boot your VM and use your
keyboard and mouse inside it. In order to swap the keyboard and mouse between
host and the guest, press both **left control** and **right control** at the
same time.

## IVSHMEM Support
> Note: This section is only useful if you are going to use either [Scream with IVSHMEM](#scream--ivshmem) or [Looking Glass](#looking-glass).

- Inside your Windows box's **Device Manager**, go to **System Devices** and select **PCI standard RAM Controller**, then update it with [RedHat's IVSHMEM drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/upstream-virtio/) (preferentially v0.1-161+).

## KMonad Support

If you are using [[Elegant remappings with KMonad | KMonad]], you will notice
that it grabs your keyboard's `udev` device and it won't output anything while
KMonad is actively using this keyboard. We can work around this by symlinking
the output device that KMonad creates into a known name that we can pass to our
VM.

Inside my KMonad configuration, I have this relevant line:
```js
output (uinput-sink "KMonad output")
```
This sets the name of the `udev` device that KMonad creates. Having this
information, we can write an `udev` rule that detects and symlinks this device
to a known path:

```nix
services.udev.extraRules = ''
  # Symlink KMonad device
  ACTION=="add", ATTRS{name}=="KMonad output", SYMLINK+="KMONAD_DEVICE"
'';
```

Now that we have the symbolic link `/dev/KMONAD_DEVICE`, which points to the dynamic
input that KMonad created we can provide it inside the VM's XML file:

```xml
<input type="evdev">
  <source dev="/dev/KMONAD_DEVICE" grab="all" repeat="on"/>
</input>
```

## Audio Support
At this point you should already have a working Windows box which can see and
use your GPU, but it probably doesn't have any sound output.

### Scream + Bridged Network

#### Host Setup
- Set the network device to **Bridge Device** and **Device name** to your
  virtual bridge, usually **virbr0**.
- Inside your NixOS configuration, add:
  ```nix
  systemd.user.services.scream-network = {
    enable = true;
    description = "Scream network";
    serviceConfig = {
      ExecStart = "${pkgs.scream}/bin/scream -o pulse -i virbr0";
      Restart = "always";
    };
    wantedBy = [ "default.target" ];
    requires = [ "pipewire.service" ]; # Change to pulseaudio.service if using it
  };
  ```
  Then rebuild your system.

#### Guest Setup
- Download and install [VirtIO drivers](https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/#virtio-win-direct-downloads) ([virtio-win-iso](https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md)).
- Download and Install [Scream](https://github.com/duncanthrax/scream/releases/).
  > Note: If you previously had setup [Scream with IVSHMEM](#scream--ivshmem),
  > remember to remove the registry entry that makes Scream use IVSHMEM.

You should now be able to hear the guest's audio on your host.

> Note: For some reason, even though the `scream-network` unit is running, the
> box doesn't output any sound until I restart the unit.
> If that also happens to you, you can do so with: `systemctl --user restart
> scream-network.service`.

<!-- TODO: Install VirtIO drivers on guest and try again to make scream work via network -->
### Scream + IVSHMEM
> Note: Setting up Scream with **IVSHMEM** is not the preferred way of doing it,
> and probably will have more disadvantages than advantages.

#### Host Setup
  - Add the following to your NixOS configuration and rebuild it:
    ```nix
     # Pipewire + pulseaudio support (you can also use just pulseaudio)
     services.pipewire = {
       enable = true;
       pulse.enable = true;
     };

    # Scream
    systemd.tmpfiles.rules = [
      "f /dev/shm/scream 0660 YOUR-USERNAME-HERE qemu-libvirtd -"
    ];

    systemd.user.services.scream-ivshmem = {
      enable = true;
      description = "Scream IVSHMEM";
      serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream -o pulse -m /dev/shm/scream";
        Restart = "always";
      };
      wantedBy = [ "default.target" ];
      requires = [ "pipewire.service" ]; # Change to pulseaudio.service if using it
    };
    ```
  - Add Scream's IVSHMEM configuration inside the `<devices>` section in the XML
    config:
    ```xml
    <shmem name="scream">
      <model type="ivshmem-plain"/>
      <size unit="M">2</size>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x11" function="0x0"/>
    </shmem>
    ```
#### Guest Setup
- [Add IVSHMEM support](#ivshmem-support)
- Download and Install [Scream Drivers](https://github.com/duncanthrax/scream/releases).
- To make the driver use **IVSHMEM**, run from an elevated shell: `REG ADD HKLM\SYSTEM\CurrentControlSet\Services\Scream\Options /v UseIVSHMEM /t REG_DWORD /d 2`.

> Note: If your box's sound doesn't work and the `scream-ivshmem` unit is running,
> check the note in end of the [Scream + Bridged Network](#scream--bridged-network).

You should now be able to hear the guest's audio on your host.

## Video support
### Looking Glass
Looking Glass enables us to view our box graphical output from our XServer
session.

#### Host Setup

- Add this to your NixOS configuration:
  ```nix
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 YOUR-USERNAME-HERE qemu-libvirtd -"
  ];

  environment.systemPackages = with pkgs; [
    looking-glass-client
  ];
  ```
  Then rebuild your NixOS configuration and reboot the system.

- Add Looking Glass' required configuration inside the `<devices>` section in the box's XML:
  ```xml
  <!--
  You only need to add `<graphics>` and `<video>` if you are going to use the
  spice server.

  If you prefer swapping your keyboard and mouse between your host and the VM, 
  just don't add these two properties and lauch `looking-glass-client` with the 
  `-s no` flag.
  -->
  <graphics type="spice" autoport="yes">
    <listen type="address"/>
  </graphics>
  <video>
    <model type="none"/>
  </video>

  <!-- Required -->
  <shmem name='looking-glass'>
    <model type='ivshmem-plain'/>
    <size unit='M'>32</size>
  </shmem>
  ```

  See [Looking Glass' documentation](https://looking-glass.io/docs/stable/install/#determining-memory) in order to calculate how much memory you should give to Looking Glass (although 32M should handle most of the cases).


#### Guest Setup
Inside your Windows box, you will need to:
- [Add IVSHMEM support](#ivshmem-support).
- [Download and install `Looking Glass (host)`](https://looking-glass.io/downloads).

You should now be able to run something like `looking-glass-client -s no -F -f /dev/shm/looking-glass` on your host and see your guest graphical output.

> Note: The version of both your Looking Glass client and host applications must match.

## USB Support
If you need to use your USBs to wire up say a pendrive or an external HD, you
can easily plug them into your PC and pass them to your guest through the **Add
Hardware** button inside the box's details.

## Partition Support
To passthorugh native partitions, create them on your host, then inside the **Add
Hardware** menu, select **Storage**, uncheck **Create a disk image for the
virtual machine**, check **Select or create custom storage** and add the path do
your partition inside the input (e.g: `/dev/sdb2`).

# Performance Improvements

## Changing number of CPU cores
I've initially had some trouble with poor CPU performance, In order to improve
it I went into the **CPUs** section inside the box's details and checked
**Manually set CPU topology**, from here you can increase the number of real
cores working with the VM.

## CPU Pinning

# Conclusion
While tinkering with and learning more about `VFIO` and `QEMU`/`libvirt`, I've
managed to find an interesting virtual machine workflow:
- Audio: Scream + Bridged Network.
- Video: I'm using both the native GPU's output and Looking Glass, depending on what
  I'm doing.
- Inputs: I'm using both my keyboard and mouse as `evdev` inputs, so I can swap
  between the bare metal and the virtual machine. I'm also using KMonad's output
  device as my keyboard device.

The experience has been much greater than dual boot, since I can just open
Looking Glass and use Windows as if it were just another workspace in my window
manager. Now I can use both the OSses at the same time and don't need to waste time
waiting for system reboots.

I hope this post to be useful for whoever want to try a **virtual machine + GPU
passthrough** workflow, be it another reader or myself trying to setup it again
after formatting the computer.

This is how my final NixOS configuration looks like:

```nix
{ pkgs, ... }:

let
  username = "vini";
in
{
  boot = {
    kernelParams = [
      # https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_IOMMU
      "intel_iommu=on"
      "iommu=pt"

      "pcie_aspm=off"
    ];

    kernelModules = [
      "kvm-intel"
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio_virqfd"
      "vfio"
    ];

    blacklistedKernelModules = [
      "nvidia"
      "nouveau"
    ];

    extraModprobeConfig = "options vfio-pci ids=10de:1b81";

    postBootCommands = ''
      DEVS="0000:0f:00.0 0000:0f:00.1"

      for DEV in $DEVS; do
        echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      done
      modprobe -i vfio-pci
    '';
  };

  services.udev.extraRules = ''
    # Symlink KMonad device
    ACTION=="add", ATTRS{name}=="KMonad output", SYMLINK+="KMONAD_DEVICE"
  '';

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 ${username} qemu-libvirtd -"
  ];

  systemd.user.services.scream-network = {
    enable = true;
    description = "Scream network";
    serviceConfig = {
      ExecStart = "${pkgs.scream}/bin/scream -o pulse -i virbr0";
      Restart = "always";
    };
    wantedBy = [ "default.target" ];
    requires = [ "pipewire.service" ];
  };

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      ovmf.enable = true;
      runAsRoot = false;
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
    looking-glass-client
  ];
}
```

# Resources
- [Arch Wiki's PCI Passthrough Article](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [Notes on PCI Passthrough on NixOS using QEMU and VFIO](https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html)
- [Scream Project](https://github.com/duncanthrax/scream)
- [NixOS VFIO PCIe Passthrough](https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916)
- [Looking Glass Setup](https://looking-glass.io/docs/stable/install/)
- [Using Scream over LAN](https://looking-glass.io/wiki/Using_Scream_over_LAN)
- [Sound while in Looking Glass: How to get it working](https://forum.level1techs.com/t/sound-while-in-looking-glass-how-to-get-it-to-work-properly-in-november-2020/163448/7)
