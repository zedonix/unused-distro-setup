{
  boot.kernelModules = [
    "kvm-intel"
  ];
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
      };
    };
    # spiceUSBRedirection.enable = true;
  };
}
