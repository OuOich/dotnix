{
  inputs' ? { },
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  maybeInputPkgs = {
    deploy-rs = inputs'.deploy-rs.packages.deploy-rs or pkgs.deploy-rs;
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    nil
    statix
    nixfmt-rfc-style
    prettier

    sops

    maybeInputPkgs.deploy-rs
  ];

  shellHook = ''
    echo -e "\033[36m# --------------> [ NIX SHELL ] <-------------- #\033[0m"
  '';
}
