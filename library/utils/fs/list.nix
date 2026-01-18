{ lib, ... }:

{
  listNixFilesRecursive =
    dir: builtins.filter (f: lib.hasSuffix ".nix" (toString f)) (lib.filesystem.listFilesRecursive dir);

  listNixFilesRecursiveWithExecludes =
    dir: excludes:
    builtins.filter (f: !(builtins.elem f excludes) && (lib.hasSuffix ".nix" (toString f))) (
      lib.filesystem.listFilesRecursive dir
    );
}
