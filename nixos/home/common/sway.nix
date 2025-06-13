{
  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;
    xwayland = true;
  };
  home.file."./.config/sway" = {
    source = ../../hosts/old/sway;
    recursive = true;
  };
}
