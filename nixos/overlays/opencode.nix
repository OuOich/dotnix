final: prev:

let
  inherit (final) lib;
  inherit (prev.opencode) version;
in
{
  opencode-baseline = final.stdenvNoCC.mkDerivation {
    pname = "opencode";
    inherit version;

    src = final.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64-baseline.tar.gz";
      hash = "sha256-vAyJ9m8W6XCFp/h8EhqmdCFFlFhNorqXJdUpbyH27J0=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [ final.makeBinaryWrapper ];

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 opencode $out/bin/.opencode-wrapped

      makeWrapper ${final.glibc}/lib/ld-linux-x86-64.so.2 $out/bin/opencode \
        --add-flags "--library-path ${
          lib.makeLibraryPath [
            final.glibc
            final.stdenv.cc.cc.lib
          ]
        }" \
        --add-flags "$out/bin/.opencode-wrapped" \
        --prefix PATH : ${lib.makeBinPath [ final.ripgrep ]}

      runHook postInstall
    '';

    meta = prev.opencode.meta // {
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };

  opencode = final.opencode-baseline;
}
