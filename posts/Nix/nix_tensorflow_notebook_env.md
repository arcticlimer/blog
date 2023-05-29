---
date: 2021-01-09
title: Reproducible Machine Learning Environment With Nix
---

<!-- toc -->

# Intro
Recently I've been tinkering with machine learning, and wanted to have a local
reproducible *Python* development environment which supports GPU. This post is meant to
share the resulting *Nix* and *poetry* configs.

# Creating The Environment
## Installing Tensorflow
Tensorflow with CUDA is the great star here, and you have 2 main ways of installing it using *Nix*:
- Building `tensorflow-gpu` from source, which uses a lot of computational
    resources and time.
- Downloading the required **CUDA** libraries and adding them to your
    `$LD_LIBRARY_PATH`.

This post will go with the latter.

## flake.nix
```nix
{
  description = "Tensorflow + CUDA development environment";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    {
      # Nixpkgs overlay providing the application
      overlay = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: prev: {
          pythonEnv = prev.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            preferWheels = true;
          };
        })
      ];
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
          config.allowUnfree = true;
        };
      in
      rec {
        devShell = pkgs.mkShell {
          name = "tf-dev-environment";
          nativeBuildInputs = [ pkgs.poetry ];

          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.cudatoolkit_11}/lib:${pkgs.cudnn_cudatoolkit_11}/lib:${pkgs.cudatoolkit_11.lib}/lib:$LD_LIBRARY_PATH

            alias jupyter="poetry run jupyter"
          '';
        };
    }));
}
```
Note that this assumes OpenGL libraries in your `$LD_LIBRARY_PATH`. If you're
using NixOS, you can set the `hardware.opengl.setLdLibraryPath` option to
`true`.  On other distros, you might be able to use *nixGL* or set the path
manually, if it's not already set.

## pyproject.toml
```toml
[tool.poetry]
name = "cuda-tensorflow"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = ">=3.9,<3.11"
tf-nightly = "^2.9.0-alpha.20220109"
keras = "^2.7.0"
numpy = "^1.22.0"
matplotlib = "^3.5.1"
jupyter = "^1.0.0"

[tool.poetry.dev-dependencies]

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
```

Notice: Depending on when you find this, you might need to update these dependencies.

# Resources
- [NixOS Wiki page on Tensorflow](https://nixos.wiki/wiki/Tensorflow)
- [poetry2nix](https://github.com/nix-community/poetry2nix)
