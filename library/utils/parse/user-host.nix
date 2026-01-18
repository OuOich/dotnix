_:

{
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
}
