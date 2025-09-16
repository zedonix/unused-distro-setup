{
  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        devices = [ "nodev" ];
        useOSProber = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
