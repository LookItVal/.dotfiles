# `my.lean = true` drops the big GUI apps so the system fits on a small (~30 GB)
# test stick. Set in hosts/usb; the internal install keeps the full set.
{ lib, ... }:
{
  options.my.lean = lib.mkEnableOption "trimmed package set for small test sticks";
}
