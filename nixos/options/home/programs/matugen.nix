{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.dotnix.programs.matugen;

  matugenPkg = inputs.matugen.packages.${pkgs.system}.default;
in
{
  options.dotnix.programs.matugen = {
    enable = lib.mkEnableOption "Whether to enable matugen.";

    config = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Matugen configuration (TOML).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ matugenPkg ];

    xdg.configFile."matugen/config.toml".text = cfg.config;

    # home.activation.runMatugenImage = lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
    #   run ${matugenPkg}/bin/matugen image ${config.settings.theme.wallpaper.default}
    # '';
  };
}
