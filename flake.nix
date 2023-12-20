{
  description = "Personal blog";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ hugo ];
        };
        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "personal-notes";
          src = nixpkgs.lib.cleanSource ./.;
          buildPhase = "pageturtle build";
          installPhase = ''
            mkdir -p $out/dist
            cp -r ./dist/* $out/dist
          '';
          buildInputs = [ ];
        };
      }
    );
}
