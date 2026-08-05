{
  options,
  lib,
  ...
}:

lib.mkMerge [
  {
    programs.gpg = {
      enable = true;

      settings = {
        default-key = "18D6A9F0636C87CEE363E647D220DCA09C867D9A";
      };
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
