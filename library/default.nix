{ pkgs, lib, ... }:

rec {
  utils = {
    isEmptyList = list: (builtins.length list) == 0;

    listNixFilesRecursive =
      dir: builtins.filter (p: lib.hasSuffix ".nix" (toString p)) (lib.filesystem.listFilesRecursive dir);

    listNixFilesRecursiveWithExecludes =
      dir: excludes:
      builtins.filter (p: !(builtins.elem p excludes) && (lib.hasSuffix ".nix" (toString p))) (
        lib.filesystem.listFilesRecursive dir
      );

    getUserNamesInGroup =
      config: groupName:
      lib.unique (
        (
          if builtins.hasAttr groupName config.users.groups then
            config.users.groups.${groupName}.members
          else
            [ ]
        )
        ++ (map (u: u.name) (
          lib.filter (u: u.group == groupName || (builtins.elem groupName u.extraGroups)) (
            builtins.attrValues config.users.users
          )
        ))
      );

    getUsersInGroup =
      config: groupName:
      let
        names = utils.getUserNamesInGroup config groupName;
      in
      map (name: config.users.users.${name}) (
        lib.filter (name: builtins.hasAttr name config.users.users) names
      );
  };
}
