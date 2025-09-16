{
  services.mako = {
    enable = true;
    borderSize = 2;
    padding = "8";
    width = 400;
    height = 40;
    layer = "overlay";
    backgroundColor = "#282828";
    textColor = "#ebdbb2";
    borderColor = "#458588";
    extraConfig = ''
      [app-name=volume.sh]
      history=0

      [urgency=low]
      background-color=#3c3836
      text-color=#b8bb26

      [urgency=normal]
      background-color=#282828
      text-color=#ebdbb2

      [urgency=critical]
      background-color=#cc241d
      text-color=#fbf1c7
    '';
  };
}
