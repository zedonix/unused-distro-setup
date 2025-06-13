{
  description = "Configuration Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      home-manager,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          system = system;
          modules = [
            ./hosts/old/configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };
      homeConfigurations = {
        piyush = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/piyush/home.nix ];
        };
      };
    };
}
