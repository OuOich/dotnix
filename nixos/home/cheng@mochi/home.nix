{ osConfig, ... }:

{
  home.username = osConfig.users.users.cheng.name;
  home.homeDirectory = osConfig.users.users.cheng.home;

  imports = [
    # Import all personal configurations
    ../cheng
  ];

  home.stateVersion = "26.05";
}
