# Services every server runs: remote login, name discovery, web dashboard.
{ config, ... }:
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

  # Never sleep. Old laptops run these closed, so ignore the lid,
  # and remove the sleep states entirely so nothing else can trigger them.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

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

  # Cockpit web dashboard: https://<hostname>.local:9090, log in as val.
  # It rejects logins from addresses not listed here (only localhost by default).
  services.cockpit = {
    enable = true;
    openFirewall = true;
    allowed-origins = [ "https://${config.networking.hostName}.local:9090" ];
  };
}
