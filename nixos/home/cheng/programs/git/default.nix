{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Cheng";
        email = "chengcheng@miao.ms";
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
      key = "6BE182A0DE04D4E9A64244EE9D370BF9A2837224";
    };
  };
}
