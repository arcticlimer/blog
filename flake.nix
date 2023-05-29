{
  description = "Personal blog";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    pageturtle.url = "github:viniciusmuller/pageturtle";
  };

  outputs = { self, flake-utils, pageturtle, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pageturtle-pkg = pageturtle.defaultPackage.${system};
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ pageturtle-pkg ];
        };
        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "personal-notes";
          src = ./.;
          buildPhase = "pageturtle build";
          installPhase = ''
            mkdir -p $out/dist
            cp -r ./dist/* $out/dist
          '';
          buildInputs = [ pageturtle-pkg ];
        };
      }
    );
}
