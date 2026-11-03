# Host-side setup for lerd (https://github.com/lerd-env/lerd), which stays installed the
# usual way into ~/.local (its own installer, `lerd update`). lerd runs PHP, nginx,
# databases and dnsmasq as rootless podman containers; NixOS only has to provide what
# lerd's installer would otherwise change in /etc. Mirrors what it set up on Arch:
#   /etc/sysctl.d/99-lerd-ports.conf          net.ipv4.ip_unprivileged_port_start=80
#   /etc/NetworkManager/conf.d/lerd.conf      [main] dns=dnsmasq
#   /etc/NetworkManager/dnsmasq.d/lerd.conf   server=/test/127.0.0.1#5300
# The PATH entry for ~/.local/share/lerd/bin is already in zshrc.
{ config, lib, pkgs, ... }:
let
  cfg = config.my.lerd;
in
{
  options.my.lerd.enable = lib.mkEnableOption "host setup for lerd (rootless podman dev environment)";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    users.users.val.autoSubUidGidRange = true; # rootless podman

    # lerd's nginx binds 80/443 rootless.
    boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

    # *.test -> lerd's dnsmasq container on 127.0.0.1:5300
    networking.networkmanager.dns = "dnsmasq";
    environment.etc."NetworkManager/dnsmasq.d/lerd.conf".text = ''
      server=/test/127.0.0.1#5300
    '';

    # LAN sharing (phone testing). `lerd lan:share` may use extra ports: add them here.
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # lerd downloads prebuilt binaries (fnm-managed node, bun, mkcert, phpantom_lsp).
    programs.nix-ld.enable = true;
  };
}
