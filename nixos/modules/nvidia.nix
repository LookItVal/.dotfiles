# HP OMEN Slim 16 (QUINN-OMEN): Intel Arrow Lake-P iGPU + NVIDIA RTX 5070 Max-Q
# (GB206M / Blackwell). Bus IDs below come from `lspci -D` on the Arch install:
#   0000:00:02.0 Intel   ->  PCI:0:2:0
#   0000:01:00.0 NVIDIA  ->  PCI:1:0:0
# Blackwell is only supported by the *open* kernel modules, driver >= 570.
{ config, lib, pkgs, ... }:
let
  cfg = config.my.nvidia;
in
{
  options.my.nvidia = {
    enable = lib.mkEnableOption "Intel + NVIDIA PRIME hybrid graphics";

    primeMode = lib.mkOption {
      type = lib.types.enum [ "offload" "sync" ];
      default = "offload";
      description = ''
        offload: iGPU drives the panel, use `nvidia-offload <cmd>` for dGPU (best battery).
        sync:    dGPU renders everything (simplest for external monitors wired to the dGPU).
      '';
    };

    intelBusId = lib.mkOption { type = lib.types.str; default = "PCI:0:2:0"; };
    nvidiaBusId = lib.mkOption { type = lib.types.str; default = "PCI:1:0:0"; };
  };

  config = lib.mkIf cfg.enable {
    # "modesetting" drives the Intel iGPU; "nvidia" must be listed to pull in the driver.
    services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt ];
    };

    hardware.nvidia = {
      open = true;
      modesetting.enable = true; # nvidia_drm.modeset=1 (same as the Arch cmdline)
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;

      powerManagement.enable = true;
      powerManagement.finegrained = cfg.primeMode == "offload";

      prime = {
        intelBusId = cfg.intelBusId;
        nvidiaBusId = cfg.nvidiaBusId;
        offload = lib.mkIf (cfg.primeMode == "offload") {
          enable = true;
          enableOffloadCmd = true; # provides `nvidia-offload`
        };
        sync.enable = cfg.primeMode == "sync";
      };
    };

    # Arch cmdline also had nvidia_drm.fbdev=1
    boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

    # nvtop / nvidia-smi (used by the i3blocks gpu_* scripts) come with the driver.
    environment.systemPackages = [ pkgs.nvtopPackages.full ];
  };
}
