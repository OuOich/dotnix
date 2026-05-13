{
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.opencode = {
      enable = true;

      settings = lib.importJSON ./opencode.json;
      tui = lib.importJSON ./tui.json;
    };
  }

  (lib.optionalAttrs (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        ".local/share/opencode"
      ];
    };
  })
]
