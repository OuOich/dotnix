{ osConfig, ... }:

{
  home.username = osConfig.users.users.cheng.name;
  home.homeDirectory = osConfig.users.users.cheng.home;

  home.stateVersion = "26.05";
}
