{
  # Impermanence Home Manager paths are namespaced under home.homeDirectory automatically.
  home.persistence."/persist" = {
    directories = [
      "Desktop"
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Public"
      "Templates"
      "Videos"

      # ".config"
      # ".local/share"
      # ".local/state"

      {
        directory = ".gnupg";
        mode = "0700";
      }

      "data"

      ".local/state/nix/profiles"
    ];

    files = [
      ".config/sops-nix/age-key.txt"

      ".ssh/known_hosts"
    ];
  };
}
