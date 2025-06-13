{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    home-manager
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.piyush = import ../../home/piyush/home.nix;
}
