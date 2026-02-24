{
  sops = {
    useSystemdActivation = true;

    secrets = {
      hashed_user_password_root = {
        key = "hashed_user_passwords/root";
        neededForUsers = true;
      };
      hashed_user_password_cheng = {
        key = "hashed_user_passwords/cheng";
        neededForUsers = true;
      };
    };
  };
}
