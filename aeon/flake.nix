{
  description = "AEON — ein persönliches Life-OS (Fleet)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-25.05";   # passend zu nixpkgs 25.05 (sonst 'gnome'-Fehler)
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # Für den Mac später:
    # nix-darwin.url = "github:LnL7/nix-darwin";
  };

  outputs = { self, nixpkgs, home-manager, stylix, plasma-manager, ... }:
    let system = "x86_64-linux";
    in {
      # ── Flaggschiff: Windows-PC (Dual-Boot NixOS) ──
      nixosConfigurations.aeon-rig = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/aeon-rig/configuration.nix
          stylix.nixosModules.stylix
          # ── Voll-Design (Plasma: Papirus-Icons + eigenes Panel) ──
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
            home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
            home-manager.users.joshua = import ./home/joshua.nix;
          }
        ];
      };

      # ── AEON-Installer-ISO (Tailscale + Branding + aeon-install drin) ──
      nixosConfigurations.aeon-iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ modulesPath, ... }: {
            imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
          })
          ./installer/iso.nix
        ];
      };

      # Bequemer Build:  nix build .#aeon-iso
      packages.${system}.aeon-iso =
        self.nixosConfigurations.aeon-iso.config.system.build.isoImage;

      # ── Mac (nix-darwin) folgt in Phase 3 ──
      # darwinConfigurations.aeon-mac = ...
    };
}
