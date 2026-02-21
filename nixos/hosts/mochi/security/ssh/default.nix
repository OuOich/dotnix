{
  dotnix.security.sshKeysMount = {
    enable = true;

    hostKeys = {
      ed25519 = true;
      rsa = true;
    };
  };
}
