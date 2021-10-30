{
  description = "Personal blog";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    mdzk.url = "github:mdzk-rs/mdzk";
  };

  outputs = { self, flake-utils, mdzk, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mdzk-bin = mdzk.defaultPackage.${system};
        mdbook-toc = pkgs.rustPlatform.buildRustPackage rec {
          pname = "mdbook-toc";
          version = "0.7.0";
          src = pkgs.fetchFromGitHub {
            owner = "badboy";
            repo = pname;
            rev = version;
            sha256 = "sha256-k8OcdWmOQGruUMD/tUoqKLpuRLaWi4Sli/pL905/KA8=";
          };
          cargoSha256 = "sha256-IH5316yKTjY8s3VCwaHGmdlzJRmnS0QOfR8vybH64rg=";
        };
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            mdzk-bin
            mdbook-toc
          ];
        };
        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "personal-notes";
          src = ./.;
          buildPhase = "mdzk build";
          installPhase = ''
            mkdir -p $out/book
            cp -r ./book/* $out/book
          '';
          buildInputs = [
            mdzk-bin 
            mdbook-toc
          ];
        };
      }
    );
}
