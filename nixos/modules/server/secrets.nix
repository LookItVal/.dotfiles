# sops-nix: secrets live encrypted in ../../secrets/homelab.yaml and are
# decrypted at boot/switch into /run/secrets/<name>, readable by root only
# unless a secret says otherwise.
#
# Each server decrypts with its own SSH host key (converted to age), so no
# extra key has to be copied onto it. Who can decrypt is set in ../../.sops.yaml.
# Edit secrets on the laptop with:
#   cd ~/.dotfiles/nixos && nix shell nixpkgs#sops -c sops secrets/homelab.yaml
{
  sops = {
    defaultSopsFile = ../../secrets/homelab.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [ ]; # age only, no GPG
  };
}
