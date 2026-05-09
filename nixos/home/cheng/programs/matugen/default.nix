{
  config,
  options,
  lib,
  ...
}:

{
  dotnix.programs.matugen = {
    enable = true;

    config = /* toml */ ''
      [config]
      prefer = "darkness"

      # (optional: templates.noctalia)
      ${lib.optionalString
        (
          (options.programs ? noctalia-shell)
          && config.programs.noctalia-shell.enable
          && config.programs.noctalia-shell.settings.colorSchemes.predefinedScheme == "Matugen"
        )
        /* toml */ ''
          [templates.noctalia]
          input_path = "${./templates/noctalia.json}"
          output_path = "~/.config/noctalia/colorschemes/Matugen/Matugen.json"
          post_hook = "noctalia-shell ipc --any-display call colorScheme set Matugen 2>/dev/null || true"
        ''
      }
      # (optional end)

      # (optional: templates.niri)
      ${lib.optionalString
        (
          (options.programs ? niri)
          && (options.programs.niri ? finalConfig)
          && config.programs.niri.finalConfig != null
        )
        /* toml */ ''
          [templates.niri]
          input_path = "${./templates/niri.kdl}"
          output_path = "~/.config/niri/matugen.kdl"
        ''
      }
      # (optional end)
    '';
  };
}
