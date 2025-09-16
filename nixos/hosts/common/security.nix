{
  security = {
    polkit.enable = true;
    pam = {
      services.swaylock = { };
      loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
      ];
    };
  };
}
