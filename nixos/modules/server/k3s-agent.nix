# Joins this machine to the k3s cluster on server01 as a worker. Imported per
# host (see hosts/<name>/default.nix) so nodes can be enrolled one at a time.
#
# The join token is not in git. Before the first rebuild on a new node:
#   sudo install -d -m 700 /var/lib/rancher/k3s
#   sudo install -m 600 /dev/stdin /var/lib/rancher/k3s/agent-token
#   (paste the token from server01:/var/lib/rancher/k3s/server/node-token, Enter, Ctrl+D)
{ pkgs, ... }:
{
  services.k3s = {
    enable = true;
    # Nodes must not run a newer minor version than the server (v1.34).
    # Bump this only after upgrading server01.
    package = pkgs.k3s_1_34;
    role = "agent";
    # server01's DHCP address. Reserve it on the router when static DHCP is set up.
    serverAddr = "https://192.168.86.27:6443";
    tokenFile = "/var/lib/rancher/k3s/agent-token";
    # Keeps ordinary pods off the node until it's been tested. Only applied when
    # the node first registers; remove it afterward with kubectl taint.
    extraFlags = [ "--node-taint=homelab/onboarding=true:NoSchedule" ];
  };

  networking.firewall = {
    allowedTCPPorts = [ 10250 ]; # kubelet (kubectl logs/exec)
    allowedUDPPorts = [ 8472 ];  # flannel vxlan
    trustedInterfaces = [ "cni0" "flannel.1" ]; # pod traffic
  };
}
