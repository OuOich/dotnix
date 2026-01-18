{ dotnix, ... }:

{
  imports = dotnix.lib.utils.listNixFilesRecursiveWithExecludes ./. [ ./default.nix ];
}
