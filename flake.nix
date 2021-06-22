{
  description = "Flake for building bitte-ci-frontend";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  };

  outputs = { self, nixpkgs }@inputs:
    let
      overlay = final: prev: {
        mint = prev.callPackage ./pkgs/mint { };

        bitte-ci-frontend = prev.stdenv.mkDerivation {
          pname = "bitte-ci-frontend";
          version = "0.0.1";
          nativeBuildInputs = [ final.mint ];
          src = ./.;
          buildPhase = ''
            mint build
          '';

          installPhase = ''
            cp -r dist $out
          '';
        };
      };

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ overlay ];
      };
    in {
      legacyPackages.x86_64-linux = pkgs;

      packages.x86_64-linux.bitte-ci-frontend = pkgs.bitte-ci-frontend;

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.bitte-ci-frontend;

      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = with pkgs; [ mint ];
      };
    };
}
