{ pkgs, lib, ... }:

rec {
  utils = {
    isEmptyList = list: (builtins.length list) == 0;

    parseUserHost =
      input:
      if !builtins.isString input then
        throw "parseUserHost: argument must be a string, but it is a ${builtins.typeOf input}"
      else
        let
          parts = builtins.filter builtins.isString (builtins.split "@" input);
          len = builtins.length parts;
        in
        if len == 1 then
          throw "parseUserHost: invalid format in '${input}'; expected a separator '@'"
        else if len > 2 then
          throw "parseUserHost: invalid format in '${input}'; string contains multiple '@' separators"
        else
          let
            userName = builtins.elemAt parts 0;
            hostName = builtins.elemAt parts 1;
          in
          if userName == "" then
            throw "parseUserHost: invalid input '${input}'; user part cannot be empty"
          else if hostName == "" then
            throw "parseUserHost: invalid input '${input}'; host part cannot be empty"
          else
            {
              inherit userName hostName;
            };

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
