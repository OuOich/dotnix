set shell := ["/usr/bin/env", "bash", "-uc"]

[default]
_:
  @echo
  @echo -n -e "\033[35m"
  @echo "    ฅ(^•ﻌ•^ฅ)   https://github.com/OuOich/dotnix"
  @echo "    --------------------------------------------"
  @echo -n -e "\033[0m"
  @echo
  @echo -n -e "\033[34m"
  @just --list --unsorted --list-heading $'Recipes:\n' --color never
  @echo -n -e "\033[0m"

# Build target's home-manager activation package
hm-build target *nixargs:
  #!/usr/bin/env bash
  IFS="@" read -r USER HOST <<<"{{target}}"

  nix build .#nixosConfigurations.$HOST.config.home-manager.users.$USER.home.activationPackage

# Enter a nix shell with target's home-manager environment
hm-shell target *nixargs: (hm-build target nixargs)
  #!/usr/bin/env bash

  IFS="@" read -r USER HOST <<<"{{target}}"

  HM_RESULT="$(readlink -f "$(pwd)"/result)"

  HM_TMP_HOME=$(mktemp -d /tmp/hm-shell.XXXXXX)

  echo -e "\033[36m[build] Preparing home files...\033[0m"
  cp -rL "$HM_RESULT/home-files/." "$HM_TMP_HOME"
  chmod -R u+w "$HM_TMP_HOME"

  echo -e "\033[36m[nix develop] Loading...\033[0m"

  read -r -d '' NIX_EXPR <<'EOF'
    let
      self = builtins.getFlake (toString ./.);
      pkgs = import <nixpkgs> {};
    in
    pkgs.mkShell {
      packages = [ self.nixosConfigurations.$_HOST.config.home-manager.users.$_USER.home.path ];
      shellHook = ''
        export PATH="$_HM_RESULT/home-path/bin:$PATH"
        export HOME="$_HM_TMP_HOME"
        export XDG_CONFIG_HOME="$_HM_TMP_HOME/.config"
        export XDG_DATA_HOME="$_HM_TMP_HOME/.local/share"
        export XDG_CONFIG_DIRS="$XDG_CONFIG_HOME:$XDG_CONFIG_DIRS"
        export XDG_DATA_DIRS="$XDG_DATA_HOME:$XDG_DATA_DIRS"

        echo -e "\033[36m[nix develop] OK\033[0m"
      '';
    }
  EOF

  NIX_EXPR="${NIX_EXPR//\$_HOST/$HOST}"
  NIX_EXPR="${NIX_EXPR//\$_USER/$USER}"
  NIX_EXPR="${NIX_EXPR//\$_HM_RESULT/$HM_RESULT}"
  NIX_EXPR="${NIX_EXPR//\$_HM_TMP_HOME/$HM_TMP_HOME}"

  nix develop --impure --expr "$NIX_EXPR" {{nixargs}}

  rm -rf "$HM_TMP_HOME"
