{
  programs.dotnvim = {
    enable = true;

    useFlakeNixpkgs = true;
    selfContainedOverlays = true;

    defaultEditor = true;

    vimdiffAlias = true;
    vimAlias = true;
    viAlias = true;
  };
}
