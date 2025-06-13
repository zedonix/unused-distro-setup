{
  pkgs,
  ...
}:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    extraConfig = {
      modi = "drun";
      show-icons = true;
    };
    location = "center";
    theme = "gruvbox-dark";
    terminal = "${pkgs.foot}/bin/foot";
  };

}
