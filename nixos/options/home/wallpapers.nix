{
  dotnix,
  config,
  lib,
  ...
}:

let
  cfg = config.dotnix.wallpapers;

  inherit (config.home) homeDirectory;

  normalizeDirectory =
    directory:
    let
      withoutHomePrefix =
        if directory == "~" || directory == homeDirectory then
          "."
        else if lib.hasPrefix "~/" directory then
          lib.removePrefix "~/" directory
        else if lib.hasPrefix "${homeDirectory}/" directory then
          lib.removePrefix "${homeDirectory}/" directory
        else
          directory;
    in
    lib.removeSuffix "/" withoutHomePrefix;

  directoryTarget = normalizeDirectory cfg.directory;

  mkTarget =
    fileName:
    if directoryTarget == "" || directoryTarget == "." then
      fileName
    else
      "${directoryTarget}/${fileName}";

  mkWallpaperFile =
    name: wallpaper:
    let
      fileName = if builtins.isAttrs wallpaper && wallpaper ? name then wallpaper.name else name;
    in
    lib.nameValuePair (mkTarget fileName) {
      source = wallpaper;
      inherit (cfg) force;
    };
in
{
  options.dotnix.wallpapers = {
    enable = lib.mkEnableOption "Automatic mounting of wallpapers into the Home Manager user profile.";

    package = lib.mkOption {
      type = lib.types.package;
      default = dotnix.pkgs.wallpapers;
      defaultText = lib.literalExpression "dotnix.pkgs.wallpapers";
      description = "Wallpaper package used for metadata and the default wallpaper item set.";
    };

    items = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.package);
      default = cfg.package.items;
      defaultText = lib.literalExpression "config.dotnix.wallpapers.package.items";
      description = "Wallpaper files to mount, keyed by fallback target file name.";
    };

    directory = lib.mkOption {
      type = lib.types.str;
      default = "~/Pictures/Wallpapers";
      description = "Target directory under the Home Manager user's home directory.";
      example = "~/Pictures/Wallpapers";
    };

    includeMetadata = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to mount the wallpaper package metadata.json next to the wallpaper files.";
    };

    force = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether generated wallpaper files may overwrite existing Home Manager targets.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !(lib.hasPrefix "~" cfg.directory) || cfg.directory == "~" || lib.hasPrefix "~/" cfg.directory;
        message = "dotnix.wallpapers.directory only supports '~' as the current home shortcut.";
      }
      {
        assertion =
          !(lib.hasPrefix "/" cfg.directory)
          || cfg.directory == homeDirectory
          || lib.hasPrefix "${homeDirectory}/" cfg.directory;
        message = "dotnix.wallpapers.directory must be relative to the Home Manager user's home directory.";
      }
    ];

    home.file =
      lib.mapAttrs' mkWallpaperFile cfg.items
      // lib.optionalAttrs cfg.includeMetadata {
        ${mkTarget "metadata.json"} = {
          source = "${cfg.package}/share/wallpapers/metadata.json";
          inherit (cfg) force;
        };
      };
  };
}
