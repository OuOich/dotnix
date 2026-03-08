{ pkgs, lib }:

pkgs.stdenv.mkDerivation (
  let
    metadata = lib.importJSON ./metadata.json;

    mimeToExtList = {
      "image/jpeg" = ".jpg";
      "image/png" = ".png";
      "image/webp" = ".webp";
      "image/gif" = ".gif";
    };

    wallpaperFiles = builtins.mapAttrs (
      name: attrs:
      let
        ext =
          mimeToExtList."${attrs.file_type}"
            or (throw "Unsupported file_type: ${attrs.file_type} for ${name}");

        filename = "${name}${ext}";
      in
      {
        inherit name;

        file = pkgs.fetchurl {
          inherit (attrs) url hash;
          name = filename;

          curlOpts = if attrs.source == "pixiv" then "--referer https://www.pixiv.net" else null;
        };
      }
    ) metadata.wallpapers;
  in
  {
    pname = "dotnix.wallpapers";
    version = "0-unstable-2026-03-09";

    src = ./.;

    installPhase = /* bash */ ''
      mkdir -p $out/share/wallpapers
      cp $src/metadata.json $out/share/wallpapers/metadata.json
      #
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: w: ''
          ln -s ${w.file} $out/share/wallpapers/${w.file.name}
        '') wallpaperFiles
      )}
      #
    '';

    passthru = {
      rawMetadata = metadata;
      items = builtins.mapAttrs (name: w: w.file) wallpaperFiles;
    };

    meta = {
      description = "Wallpaper collection for Cheng's NixOS configuration";
      license = pkgs.lib.licenses.cc0;
    };
  }
)
