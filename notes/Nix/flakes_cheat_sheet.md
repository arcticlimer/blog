---
date: 2021-10-31T00:35
title: Nix Flakes Cheat Sheet
---

# Table of Contents
<!-- toc -->

# Attributes

```nix 
# Commonly used options. For full list, check https://nixos.wiki/wiki/Flakes
{
  description: ""; # String describing the flake.

  inputs = { # Set containing all the dependencies of the flake.
    <flake>.url = ""; # URL pointing to the flake.
    <flake>.flake = true; # Set this to `false` if the repository is not a flake.
  };

  outputs = { # Set containing all the outputs of the flake.
    checks.<system>.<name> = {}; # Derivation describing a check ran by `nix flake check`.
    packages.<system>.<name> = {}; # Derivation which can be built with `nix build .#<name>`.
    defaultPackage.<system> = {}; # Derivation which is built by `nix build .`.
    apps.<system>.<name> = {}; # Set describing an app which can be run by `nix run .#<name>`;
    defaultApp.<system> = {}; # Derivation which is ran by `nix run .`.
    devShell.<system> = {}; # Used by `nix develop`
    devShells.<system>.<name> = {}; # Used by `nix develop .#<name>`
  };
}
```

# Commands

- `nix develop`: Enter the flake's `devShell`.
- `nix build`: Builds a derivation of the flake. If no derivation is
  specified, it will try to build **defaultPackage**. Specify which derivation
  to build with `nix
  build .#<derivation>`
- `nix run`: Builds a derivation and run the result binary.
- `nix flake check`: Checks wether the flake builds and pass its tests.
- `nix flake update [flake-url]`: Update flake input. If `flake-url` is not
  specified update all the inputs.
- `nix flake info`: Show info about the flake.

# Examples

## Plain Flake with Package + Devshell

```nix
{
  description = "Single-platform flake without external dependencies";

  outputs = { self, nixpkgs }:
    let 
      platform = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${platform};
    in {
    devShell.${platform} = pkgs.mkShell {
      buildInputs = with pkgs; [
        hello
      ];
    };
    defaultPackage.${platform} = pkgs.stdenv.mkDerivation {
      name = "dummy-derivation";
      src = ./.;
      buildPhase = "echo 'echo helloworld!' > program";
      installPhase = ''
        mkdir -p $out/bin
        chmod +x ./program
        cp ./program $out/bin/dummy-derivation
      '';
    };
  };
}
```

## Using Flake-Utils

```nix
{
  description = "Multiplatform flake using flake-utils";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (
      system: 
      let 
        pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            hello
          ];
        };
        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "dummy-derivation";
          src = ./.;
          buildPhase = "echo 'echo helloworld!' > program";
          installPhase = ''
            mkdir -p $out/bin
            chmod +x ./program
            cp ./program $out/bin/dummy-derivation
          '';
        };
      }
    );
}
```

# Resources
- [NixOS Wiki page on Flakes](https://nixos.wiki/wiki/Flakes)
- [NixOS Wiki page on Flakes Commands](https://nixos.wiki/wiki/Nix_command/flake)
