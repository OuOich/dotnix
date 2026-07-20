{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.dotnix.programs.copyq;
in
{
  options.dotnix.programs.copyq = {
    enable = lib.mkEnableOption "Whether to enable copyq.";
    package = lib.mkPackageOption pkgs "copyq" { };

    config = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "CopyQ configuration (INI).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."copyq/copyq.conf".text = cfg.config;
  };
}
