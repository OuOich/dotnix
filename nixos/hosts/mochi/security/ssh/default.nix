{
  services.openssh.enable = true;

  dotnix.security.sshKeysMount = {
    enable = true;

    hostKeys = {
      ed25519 = true;
      rsa = true;
    };

    identityKeys = {
      "cheng@mochi" = {
        ed25519 = true;
        rsa = false;
      };
    };
  };
}
