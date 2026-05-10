{ self, ... }:

{
  stylix = {
    enable = true;
    base16Scheme = "${self}/assets/base16-schemes/carbonfox.yaml";

    autoEnable = false;
    targets = {
      console.enable = true;
      grub.enable = true;
    };
  };
}
