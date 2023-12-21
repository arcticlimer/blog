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
        anubis-theme = pkgs.fetchFromGitHub {
            owner = "Mitrichius";
            repo = "hugo-theme-anubis";
            rev = "main";
            sha256 = "sha256-ZQqmSn53b+vVhqMBtLiJmzrlAAtzPh5lnzDdG9hdksY=";
          };
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ hugo ];
          shellHook = ''
          ln -s ${anubis-theme} $(pwd)/themes/anubis
          '';
        };
        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "personal-notes";
          src = nixpkgs.lib.cleanSource ./.;
          configurePhase = ''
            mkdir themes
            ln -s ${anubis-theme} ./themes/anubis
          '';
          buildPhase = "hugo";
          installPhase = ''
            mkdir -p $out/dist
            cp -r ./public/* $out/dist
          '';
          buildInputs = with pkgs; [ hugo ];
        };
      }
    );
}
