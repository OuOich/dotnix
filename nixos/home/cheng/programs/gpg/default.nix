{
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.gpg = {
      enable = true;
    };
  }

  (lib.mkIf (options.home ? persistence) {
    home.persistence."/persist" = {
      directories = [
        {
          directory = ".gnupg";
          mode = "0700";
        }
      ];
    };
  })
]
