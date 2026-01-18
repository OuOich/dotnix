{ lib, ... }:

{
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
      names = lib.getUserNamesInGroup config groupName;
    in
    map (name: config.users.users.${name}) (
      lib.filter (name: builtins.hasAttr name config.users.users) names
    );
}
