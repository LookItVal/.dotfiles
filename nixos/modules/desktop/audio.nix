{ pkgs, ... }:
{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # pipewire-pulse: pactl/paplay in the i3 scripts keep working
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
