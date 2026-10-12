{ inputs, xpkg, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak"; # don't abort if a dotfile already exists
    extraSpecialArgs = { inherit inputs xpkg; };
    users.val = import ../home;
  };
}
