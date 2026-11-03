# Joins this machine to the k3s cluster on server01 as a worker. Imported per
# host (see hosts/<name>/default.nix) so nodes can be enrolled one at a time.
#
# The join token comes from sops (secrets/homelab.yaml, key `k3s-token`).
{ config, pkgs, ... }:
{
  sops.secrets.k3s-token.restartUnits = [ "k3s.service" ];

  services.k3s = {
    enable = true;
    # Nodes must not run a newer minor version than the server (v1.34).
    # Bump this only after upgrading server01.
    package = pkgs.k3s_1_34;
    role = "agent";
    # server01's DHCP address. Reserve it on the router when static DHCP is set up.
    serverAddr = "https://192.168.86.27:6443";
    tokenFile = config.sops.secrets.k3s-token.path;
    # Keeps ordinary pods off the node until it's been tested. Only applied when
    # the node first registers; remove it afterward with kubectl taint.
    extraFlags = [ "--node-taint=homelab/onboarding=true:NoSchedule" ];
  };

  # NFS client, for pods whose volumes live on the NFS share (192.168.86.170).
  # kubelet runs mount.nfs from k3s's PATH, so nfs-utils goes there too.
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;
  systemd.services.k3s.path = [ pkgs.nfs-utils ];

  networking.firewall = {
    allowedTCPPorts = [ 10250 ]; # kubelet (kubectl logs/exec)
    allowedUDPPorts = [ 8472 ];  # flannel vxlan
    trustedInterfaces = [ "cni0" "flannel.1" ]; # pod traffic
  };
}
