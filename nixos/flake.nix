{
  description = "val's NixOS config, ported from the Arch dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }@inputs:
    let
      system = "x86_64-linux";

      # Passed to every NixOS module AND every home-manager module.
      specialArgs = {
        inherit inputs;
        # nixpkgs is mid-way through moving xorg.<tool> to top-level <tool>.
        # Prefer the new name, fall back to the old one.
        xpkg = pkgs: name: pkgs.${name} or pkgs.xorg.${name};
      };

      mkHost = extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            ./modules
            home-manager.nixosModules.home-manager
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        # Portable test stick: boots on (almost) any UEFI machine. Same
        # modules as `internal`, only hardware/boot bits differ.
        usb = mkHost [
          disko.nixosModules.disko
          ./hosts/usb
        ];

        # The real install on the laptop's internal NVMe. hardware-configuration
        # is a placeholder until you run nixos-generate-config on the machine.
        internal = mkHost [ ./hosts/internal ];

        # Minimal installer ISO with flakes + disko + git, for the
        # "boot an ISO and run nixos-install --flake" route.
        installer = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ({ pkgs, ... }: {
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
              environment.systemPackages = [
                pkgs.git
                pkgs.neovim
                disko.packages.${system}.disko
              ];
            })
          ];
        };
      };

      # nix build .#iso  ->  result/iso/*.iso
      packages.${system}.iso =
        self.nixosConfigurations.installer.config.system.build.isoImage;
    };
}
