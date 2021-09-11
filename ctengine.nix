{ pkgs ? import <nixpkgs> { }
, pkgsLinux ? import <nixpkgs> { system = "x86_64-linux"; }
}:

pkgs.dockerTools.buildImage {
  name = "ctengine";
  config = {
    Cmd = [
      "${pkgsLinux.hello}/bin/hello;${pkgsLinux.hello}/bin/hello"
     ];
  };
}
