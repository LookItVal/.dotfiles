{
  description = "val's NixOS machines: desktops (rolling) and homelab servers (stable)";

  inputs = {
    # Desktops: rolling release.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Servers: stable release, upgraded on purpose every May/November.
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    # home-manager's branch has to match the nixpkgs it runs on.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Encrypted secrets in git (secrets/*.yaml), decrypted on each server
    # with its SSH host key. See .sops.yaml for who can decrypt what.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, home-manager-stable, disko, sops-nix, ... }@inputs:
    let
      system = "x86_64-linux";

      # Passed to every desktop NixOS module AND every desktop home-manager module.
      specialArgs = {
        inherit inputs;
        # nixpkgs is mid-way through moving xorg.<tool> to top-level <tool>.
        # Prefer the new name, fall back to the old one.
        xpkg = pkgs: name: pkgs.${name} or pkgs.xorg.${name};
      };

      mkDesktop = extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            ./modules/common
            ./modules/desktop
            home-manager.nixosModules.home-manager
          ] ++ extraModules;
        };

      # Every server = the shared modules + its own hosts/<name> folder.
      mkServer = name:
        nixpkgs-stable.lib.nixosSystem {
          modules = [
            home-manager-stable.nixosModules.home-manager
            sops-nix.nixosModules.sops
            ./modules/common
            ./modules/server
            ./hosts/${name}
          ];
        };
    in
    {
      nixosConfigurations = {
        # Portable test stick: boots on (almost) any UEFI machine. Same
        # modules as `internal`, only hardware/boot bits differ.
        usb = mkDesktop [
          disko.nixosModules.disko
          ./hosts/usb
        ];

        # The real install on the laptop's internal NVMe. hardware-configuration
        # is a placeholder until you run nixos-generate-config on the machine.
        internal = mkDesktop [ ./hosts/internal ];

        # Homelab: nixos-rebuild switch --flake ~/.dotfiles/nixos
        node2 = mkServer "node2";
        node3 = mkServer "node3";

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

      packages.${system} = {
        # nix build .#iso  ->  result/iso/*.iso
        iso = self.nixosConfigurations.installer.config.system.build.isoImage;

        # Our own packages. Also installable on non-NixOS machines with Nix:
        #   nix profile add ~/.dotfiles/nixos#neoclear
        neoclear = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/neoclear { };
      };
    };
}
