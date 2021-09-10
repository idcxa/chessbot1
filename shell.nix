let
  nixpkgs = import <nixpkgs> { };
in
with nixpkgs;
nixpkgs.mkShell {
  buildInputs = [
    python39Packages.pip
    python39Packages.virtualenv
    cargo
    ];
  }
