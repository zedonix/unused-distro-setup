{
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "piyush"
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };
}
