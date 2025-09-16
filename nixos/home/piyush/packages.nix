{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    texliveBookPub
    libnotify
    openssl

    wineWowPackages.waylandFull

    sway-audio-idle-inhibit
    wl-clipboard
    wl-clip-persist
    slurp
    shotman

    xonotic

    swayimg
    swayidle
    swaylock

    pcmanfm
    onlyoffice-desktopeditors
    gimp
    virt-manager
    qalculate-gtk

    gcc
    asciinema
    yt-dlp

    zip
    unzip
    unrar
    gzip

    htop
    fastfetch
    speedtest-cli

    lua
    python3Full
    clang-tools

    noto-fonts
    noto-fonts-color-emoji
    (nerdfonts.override {
      fonts = [ "Iosevka" ];
    })
  ];
}
