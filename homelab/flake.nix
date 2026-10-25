{
  description = "val's homelab servers";

  # Where packages come from. Stable release for servers, matching the
  # version node2 was installed with (system.stateVersion = "26.05").
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Manages files in ~ (dotfiles). Its release branch must match nixpkgs.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs"; # reuse our nixpkgs, don't pin a second one
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # Every server = the shared modules + its own hosts/<name> folder.
      mkServer = name:
        nixpkgs.lib.nixosSystem {
          modules = [
            home-manager.nixosModules.home-manager
            ./common/base.nix
            ./common/server.nix
            ./common/shell.nix
            ./hosts/${name}
          ];
        };
    in
    {
      # nixos-rebuild switch --flake ~/.dotfiles/homelab#node2
      nixosConfigurations = {
        node2 = mkServer "node2";
        node3 = mkServer "node3";
      };
    };
}
