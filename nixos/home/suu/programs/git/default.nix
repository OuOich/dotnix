{ config, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Xin Su";
        email = "suu@miao.ms";
      };

      init = {
        defaultBranch = "master";
      };

      commit = {
        gpgSign = true;
        verbose = true;
      };

      pull = {
        rebase = true;
      };
    };

    signing = {
      format = "openpgp";
      key = config.programs.gpg.settings.default-key;
    };
  };
}
