{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkMerge [
  {
    home.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      # maple-mono.truetype
      maple-mono.opentype
      maple-mono.woff2
      maple-mono.variable
      maple-mono.CN
      maple-mono.NF
      maple-mono.NF-CN
      # maple-mono.NL-TTF
      maple-mono.NL-OTF
      maple-mono.NL-Woff2
      maple-mono.NL-Variable
      maple-mono.NL-NF
      maple-mono.NL-NF-CN

      lxgw-wenkai

      noto-fonts-color-emoji
      serenityos-emoji-font
    ];

    fonts = {
      fontconfig = {
        enable = true;

        hinting = "medium";
        antialiasing = true;
        subpixelRendering = "rgb";

        defaultFonts = {
          sansSerif = [ "Noto Sans CJK SC" ];
          serif = [ "LXGW WenKai" ];
          monospace = [ "Maple Mono NF CN" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  }

  (lib.mkIf config.programs.plasma.enable {
    programs.plasma.fonts =
      let
        defaultSansFontFamily = "Noto Sans CJK SC";
        defaultMonoFontFamily = "Maple Mono NF CN";
      in
      {
        general = {
          family = defaultSansFontFamily;
          weight = "normal";
          pointSize = 10;
        };
        fixedWidth = {
          family = defaultMonoFontFamily;
          weight = "normal";
          pointSize = 10;
        };
        small = {
          family = defaultSansFontFamily;
          weight = "normal";
          pointSize = 8;
        };
        toolbar = {
          family = defaultSansFontFamily;
          weight = "normal";
          pointSize = 10;
        };
        menu = {
          family = defaultSansFontFamily;
          weight = "normal";
          pointSize = 10;
        };
        windowTitle = {
          family = defaultSansFontFamily;
          weight = "normal";
          pointSize = 10;
        };
      };
  })

  (lib.mkIf config.programs.kitty.enable {
    programs.kitty = {
      settings = {
        font_family = "Maple Mono NF CN";
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
      };

      extraConfig = /* kitty */ ''
        symbol_map U+24C2,U+26AA-U+26AB,U+1F5D1-U+1F5D3,U+10CD00-U+10CD26,U+267E-U+267F,U+203C,U+2049,U+26F7-U+26FA,U+1F5EF,U+2614-U+2615,U+1F5C2-U+1F5C4,U+1F5F3,U+E0061-U+E0069,U+1FADF-U+1FAE9,U+2747,U+1F5A8,U+2692-U+2697,U+1F56F-U+1F570,U+20E3,U+2626,U+1F492-U+1F4FD,U+1F550-U+1F567,U+261D,U+23E9-U+23F3,U+1F17E-U+1F17F,U+2139,U+1F22F,U+2B50,U+2714,U+1F3F7-U+1F469,U+2328,U+1F490,U+1FA80-U+1FA85,U+2B1B-U+2B1C,U+26CE-U+26CF,U+2753-U+2755,U+1F232-U+1F23A,U+274C,U+1F93D-U+1F945,U+2712,U+1F201-U+1F202,U+2622-U+2623,U+1F58A-U+1F58D,U+1F6E9,U+2638-U+263A,U+1F5E8,U+1F473,U+2716,U+26D3-U+26D4,U+26C8,U+1F9D9,U+2744,U+1F21A,U+1F6CB-U+1F6D2,U+2763-U+2764,U+1F5B1-U+1F5B2,U+21A9-U+21AA,U+26FD,U+27B0,U+3297,U+10CDD0,U+260E,U+1F471,U+1FA87-U+1FA89,U+1F680-U+1F687,U+1F7F0,U+1F396-U+1F397,U+10CD60-U+10CD6B,U+1F947-U+1F96D,U+1F9D4,U+2640,U+1F5FA-U+1F64C,U+1F39E-U+1F3CC,U+1F933,U+1F96F-U+1F98E,U+303D,U+2620,U+25AA-U+25AB,U+2934-U+2935,U+2B55,U+262A,U+1F6F0,U+1F5E3,U+1F90C-U+1F931,U+1FA8F-U+1FAC6,U+2611,U+1F478-U+1F48E,U+1F938-U+1F93A,U+1F587,U+1F324-U+1F393,U+1F5BC,U+2728,U+1F689-U+1F69D,U+1F5E1,U+1F9D7,U+1F9D0-U+1F9D2,U+1F69F-U+1F6C5,U+1F9E3-U+1F9FF,U+1F399-U+1F39B,U+E006B-U+E007A,U+1F54D-U+1F54E,U+267B,U+2618,U+265F-U+2660,U+1F99C-U+1F9BB,U+1F0CF,U+26C4-U+26C5,U+F8FF,U+1F18E,U+27BF,U+2708-U+270D,U+1F004,U+10CD90-U+10CD93,U+10CDB0-U+10CDB1,U+1F191-U+1F19A,U+2600-U+2604,U+E0030-U+E0039,U+2699,U+23F8-U+23FA,U+1F500-U+1F53D,U+27A1,U+200D,U+26D1,U+2194-U+2199,U+10CDE0-U+10CDE5,U+262E-U+262F,U+3030,U+25B6,U+1F46F,U+2705,U+2665-U+2666,U+1F5DC-U+1F5DE,U+1FACE-U+1FADC,U+1F6F3-U+1F6FC,U+1F990-U+1F99A,U+1F573-U+1F57A,U+1F5A4-U+1F5A5,U+1FA70-U+1FA7C,U+25C0,U+25FB-U+25FE,U+2663,U+1F590,U+1F9BD-U+1F9CE,U+1F595-U+1F596,U+26B0-U+26B1,U+271D,U+26A0-U+26A1,U+23CF,U+26BD-U+26BE,U+26F0-U+26F5,U+270F,U+1F3CE-U+1F3F0,U+1F9DC-U+1F9E1,U+2733-U+2734,U+1FAF0-U+1FAF8,U+1F170-U+1F171,U+1F7E0-U+1F7EB,U+2757,U+2721,U+26A7,U+1F1E6-U+1F1FF,U+1F300-U+1F321,U+231A-U+231B,U+2795-U+2797,U+E007F,U+274E,U+2668,U+269B-U+269C,U+1F6EB-U+1F6EC,U+2648-U+2653,U+1F64F,U+2642,U+2702,U+1F549-U+1F54B,U+1F3F3-U+1F3F5,U+2B05-U+2B07,U+1F6D6-U+1F6D7,U+26E9-U+26EA,U+1F250-U+1F251,U+1F6DC-U+1F6E5 SerenityOS Emoji
      '';
    };
  })
]
