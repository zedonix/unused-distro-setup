{
  imports = [
    ./hardware-configuration.nix
    ../common/boot.nix
    ../common/clamav.nix
    ../common/fonts.nix
    ../common/hardware.nix
    ../common/home.nix
    ../common/networking.nix
    ../common/nix.nix
    ../common/searx.nix
    ../common/security.nix
    ../common/user.nix
    ../common/virtualisation.nix
    ../common/xkb.nix
    ../common/local.nix
  ];

  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    libinput.enable = true;
    openssh.enable = false;
  };

  services.gnome.gnome-keyring.enable = true;

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };
    dconf.enable = true;
  };

  system.stateVersion = "24.11";
}
