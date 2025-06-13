{
  pkgs,
  ...
}:
{
  imports = [
    ./packages.nix
    ../common/bash.nix
    ../common/bat.nix
    ../common/chromium.nix
    ../common/cliphist.nix
    ../common/direnv.nix
    ../common/eza.nix
    ../common/fd.nix
    ../common/foot.nix
    ../common/fzf.nix
    ../common/gh.nix
    ../common/git.nix
    ../common/gtk.nix
    ../common/htop.nix
    ../common/mako.nix
    ../common/mpv.nix
    ../common/neovim.nix
    ../common/newsboat.nix
    ../common/ripgrep.nix
    ../common/tofi.nix
    ../common/sway.nix
    ../common/tmux.nix
    ../common/zathura.nix
    ../common/xdg.nix
  ];
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "piyush";
    homeDirectory = "/home/piyush";
    stateVersion = "24.11";
    pointerCursor = {
      gtk.enable = true;
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  fonts.fontconfig.enable = true;
}
