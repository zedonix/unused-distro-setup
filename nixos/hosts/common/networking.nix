{
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      enable = false;
      allowedTCPPorts = [
        80
        443
      ];
    };
  };
}
