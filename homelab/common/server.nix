# Services every server runs: remote login and name discovery.
{ ... }:
{
  # SSH. Opens port 22 in the firewall automatically.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      # Still on so you can't lock yourself out. Turn off once key login works.
      PasswordAuthentication = true;
    };
  };

  # Laptop's public key (~/.ssh/id_ed25519.pub). Public keys are safe to commit.
  users.users.val.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrH8bsWGbEGiDFmb8jcy9h9jRjzZZ2N4ej+jdUwdPTS"
  ];

  # Avahi (mDNS): makes this machine reachable as <hostname>.local, and lets it
  # resolve other .local names. Opens UDP 5353 in the firewall automatically.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
}
