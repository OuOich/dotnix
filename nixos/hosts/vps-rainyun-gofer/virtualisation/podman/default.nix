{
  virtualisation.podman = {
    enable = true;

    autoPrune = {
      enable = true;
      dates = "weekly";
    };

    defaultNetwork.settings.dns_enabled = true;
  };
}
