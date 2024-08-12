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
            rev = "871cb40";
            sha256 = "sha256-utJXw8/9YFhctQyPONqYnLP6Qm5c6cq52Czg/pl1bPQ=";
          };
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ hugo ];
          shellHook = ''
          ln -sfn ${anubis-theme} $(pwd)/themes/anubis
          '';
        };
        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "personal-notes";
          src = nixpkgs.lib.cleanSource ./.;
          configurePhase = ''
            mkdir -p themes
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
