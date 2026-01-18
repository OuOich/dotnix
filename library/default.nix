{ pkgs, lib, ... }:

lib.fixedPoints.makeExtensible (
  self:
  let
    excludes = [
      ./default.nix
    ];

    modules = builtins.filter (
      f:
      !(builtins.elem f excludes)
      && !(lib.hasPrefix "_" (baseNameOf f))
      && (lib.hasSuffix ".nix" (toString f))
    ) (lib.filesystem.listFilesRecursive ./.);

    callLib =
      file:
      import file {
        inherit pkgs;
        lib = lib.extend (_: _: self);
      };

    dotnixLib = builtins.foldl' lib.recursiveUpdate { } (
      map (
        m:
        let
          kind = builtins.head (lib.path.subpath.components (lib.path.removePrefix ./. m));
          funcs = callLib m;
        in
        if kind == "top-level" then funcs else { ${kind} = funcs; }
      ) modules
    );
  in

  dotnixLib
)
