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
      key = "18D6A9F0636C87CEE363E647D220DCA09C867D9A";
    };
  };
}
