---
date: 2021-10-26T14:15
title: Elegant Remappings With KMonad
---

# Table of Contents
<!-- toc -->

# Intro
I've already had a lot of headaches trying to remap keys on Linux/NixOS. After
failing to achieve my goals with `xmodmap` and others, I was sure there had to
be a better solution, and then I've found KMonad.

# What is KMonad?
KMonad is a multiplatform key remapping software which uses a lisp-like
declarative configuration language.

# Why use KMonad?
Once you get used to it, KMonad provides a pretty stable experience and a sweet
way to configure your key remappings.

## Pros
- It works in a system-wide manner, so it doesn't matter whether you are inside
  a TTY rescuing your computer or relaxing inside your X session, your
  key remappings will work.
- It's pretty easy to define configurations for multiple keyboards and switch
  between them.
- It works. Seriously. I cannot stress this enough, I've spent a lot of time
  using programs to detect the keycodes that my keyboard was emitting and
  writing some cryptic commands inside `xmodmap`'s `.xkb` files (and guess what,
  it didn't worked). With KMonad I literally draw my keyboard in ASCII
  and change the characters' placement. And it works.
- It supports some fancy stuff such as macros, layers, composite characters, the
  ability to run shell commands when pressing a key, etc...

## Cons
- It has a steep learning curve, and you probably will need to read their ~1000
  lines lisp-like file tutorial to start using it.
- You still need to change a few lines in your configuration files in order to
  make them run in another platform.

# Using KMonad with NixOS
Since KMonad is still not available directly into NixOS as a system module, the
current way to use KMonad is through [their own NixOS module](https://github.com/kmonad/kmonad/blob/master/doc/installation.md#nixos).

## The Nix Derivation
With these settings, KMonad should already start along with your NixOS system.

```nix
{ pkgs, ... }:

let
  # The KMonad derivation (binary)
  kmonad = (import ../../pkgs/kmonad/derivation.nix) pkgs;
in
{
  imports = [
    # The KMonad NixOS module
    ./kmonad.nix
  ];

  services.kmonad = {
    enable = true;
    configfiles = [ ../../pkgs/kmonad/configs/ck61.kbd ];
    package = kmonad;
  };

  services.xserver = {
    xkbOptions = "compose:ralt";
    layout = "us";
  };

  users.extraUsers.your_username = {
    extraGroups = [ "input" "uinput" ];
  };
}
```

For more details about this Nix snippet, check the KMonad section about Nix and
the docs of their NixOS module.

## The KMonad Config
My current keyboard is a `Motospeed CK61`. It has a pretty good quality, but a
terrible usability. It has a confusing layer system, which kills any possibility
of using the arrow keys, some miscellaneous keys (home, end, page up, etc...),
or `F1-F12` keys quickly. Also, it doesn't have the tilde (yes, you've read that
right, there is not way to make a beautiful `~` by pressing a key). I mostly use
KMonad to fix these keyboard quirks, this is a relevant part of my current configuration:

```lisp
(defsrc
  esc  1    2    3    4    5    6    7    8    9    0    -    =    bspc
  tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
  caps a    s    d    f    g    h    j    k    l    ;    '    ret
  lsft z    x    c    v    b    n    m    ,    .    /    rsft
  lctl lmet lalt           spc            ralt cmp  rctl
)

(deflayer base
  grv   _    _    _    _    _    _    _    _    _    _    _    _    _
  _     _    _    _    _    _    _    _    _    _    _    _    _    _
  esc   _    _    _    _    _    _    _    _    _    _    _    _
  _     _    _    _    _    _    _    _    _    _    _    _
  lmet  lctl _              _              lalt rctl @ext
)

(deflayer extra
  _    f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12  _
  _    _    up   _    _    _    _    _    _    _    _    ssrq @pau _
  _    left down rght _    _    _    _    ins  home pgup pgdn _
  _    _    _    _    _    _    _    _    del  end  _    @mat
  _    _    _              _              _    _    @bas
)
```

You can see how I use it to create a new layer to make arrows and others usable,
turn `right-alt` into `left-alt` (`ralt` does not behave correctly when using
the `us(intl)` layout), change `ctrl` keys position, turn `caps lock` into `esc`
and add the tilde (grv) in place of the original `esc`.

# Resources
- [KMonad's GitHub Page](https://github.com/kmonad/kmonad)
- [KMonad's Tutorial](https://github.com/kmonad/kmonad/blob/master/keymap/tutorial.kbd)
- [My KMonad configuration](https://github.com/arcticlimer/dotfiles/blob/nixos/pkgs/kmonad/configs/ck61.kbd)

