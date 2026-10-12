# NixOS port of the Arch dotfiles

A flake + home-manager config that reproduces the Arch/i3 setup (i3, i3blocks, picom,
rofi, dunst, alacritty, zsh+zim, nvim, catppuccin-macchiato everywhere, the wallpaper
timer, autologin-to-startx) on NixOS, with two hosts sharing the same modules:

| host | what it is |
|---|---|
| `usb` | portable test stick: removable-EFI GRUB, disko partitioning, zram, volatile journal, broad initrd, plus a `no-nvidia` boot entry for other hardware |
| `internal` | the real install on the OMEN's NVMe, next to Windows + Arch (systemd-boot, XBOOTLDR). Hardware config is a **placeholder** until copied from the installed system. See `INSTALL.md` |
| `installer` | minimal NixOS ISO with git + disko + flakes (to boot and install from) |

> ## Read this first: nothing here has been built or evaluated
> Nix isn't installed on the machine this was written on, so **no `nix eval`, `nix build`,
> or boot test has ever run**. The code was written from memory of the nixpkgs/home-manager/disko APIs
> and will almost certainly need a round of fixes on first `nix flake check`.
> The only things that *were* executed are the sed patching script (`scripts/regen-patched.sh`)
> and `bash -n` / `zsh -n` syntax checks of the patched scripts. See `TODO.md` for the specific spots I
> don't trust.

## Layout

```
nixos/
  flake.nix                 inputs: nixpkgs-unstable, home-manager, disko
  hosts/usb/                default.nix (boot/portability), disko.nix (partitions)
  hosts/internal/           default.nix, hardware-configuration.nix (PLACEHOLDER)
  modules/                  shared NixOS modules (base, users, nvidia, desktop-i3, audio, fonts, packages, ...)
  home/                     home-manager: files.nix (symlinks), packages.nix, wallpaper.nix
  home/patched/             generated copies of the few files that can't work unchanged on NixOS
  scripts/regen-patched.sh  regenerates home/patched/ from the untouched Arch originals
  INVENTORY.md              every pacman/AUR package + config file, and how it maps
  TODO.md                   unverified bits, decisions needed
```

The original Arch files (`config/`, `arch/`, `zshrc`, ...) are untouched and remain the source of
truth. Most are linked straight into `$HOME` from `../config`; only the files with hardcoded
Arch paths (`/bin/zsh`, `/home/val`, `/etc/systemd/system/...`, state written into `~/.config`) are patched
copies. If you edit an original that has a patched copy, run `./scripts/regen-patched.sh`.

## Gotchas that will bite you

1. **Flakes only see git-tracked files.** Before any build, `git add -N nixos` (or add it for real)
   plus the currently-untracked things the config references: `arch/wallpapers/portrait/`,
   `config/autorandr/{double-2k-vertical,single-secondary,single-vertical,triple}`.
   I did not stage anything (your index has the wallpaper renames staged and I left it alone).
2. **Must be evaluated as a git flake** (`nixos-rebuild --flake ./nixos#usb` from inside the repo,
   or `git+file:///path?dir=nixos`), *not* `path:`. The modules reference `../../config` etc. outside `nixos/`.
3. `home/files.nix` links `~/.config/nvim` to **`~/.dotfiles/config/nvim`** (live), so clone the repo to `~/.dotfiles` on the new system.
4. The user password is `changeme` (`modules/users.nix`) so you can get past the i3lock screen. Change it on first boot.

## Building the USB stick

You need: the target USB stick (USB 3 + decent flash; cheap thumb drives will be painful), and either
Nix on Arch (route A/C) or a second stick for the installer ISO (route B).

First, set the target device in `hosts/usb/disko.nix` (`usbDevice`, use `/dev/disk/by-id/...`, never `/dev/sdX`).
**disko wipes that device.** Verify with `lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINT`.

### Route A: from this Arch install
```sh
sudo pacman -S nix                                   # + enable nix-daemon, add yourself to nix-users, enable flakes
cd ~/.dotfiles && git add -N nixos
nix flake check ./nixos                              # expect to fix things here first
sudo nix run github:nix-community/disko/latest -- --mode destroy,format,mount --flake ./nixos#usb
sudo nixos-install --root /mnt --flake ./nixos#usb   # nixos-install-tools; installing from non-NixOS is supported but fiddly
sudo umount -R /mnt
```
### Route B: installer ISO (the well-trodden path)
```sh
nix build ./nixos#iso                                 # or download the official minimal ISO
sudo dd if=result/iso/*.iso of=/dev/disk/by-id/<STICK-1> bs=4M status=progress oflag=sync
```
Boot stick 1 (disable Secure Boot in firmware), get the repo onto it (`git clone`, but `nixos/` must be pushed or copied over USB/scp first),
then install onto stick 2:
```sh
sudo disko --mode destroy,format,mount --flake .#usb
sudo nixos-install --flake .#usb
```
### Route C: build a disk image, then `dd` it
disko can build a raw image in a VM (`system.build.diskoImages`, needs KVM): no root, no installer. Untested here.

### First boot
Pick the stick in the firmware boot menu, GRUB lists NixOS + the `no-nvidia` specialisation (use it on any machine that isn't this laptop).
Autologin lands on tty1, `startx` starts i3, i3lock locks the screen (password: `changeme`).
Day to day: `sudo nixos-rebuild switch --flake ~/.dotfiles/nixos#usb`.

## Porting to the internal drive

> **Superseded by [`INSTALL.md`](INSTALL.md).** The current plan keeps Arch (shrink p7, new p8 for NixOS),
> uses systemd-boot with p5 as XBOOTLDR instead of GRUB, and installs `bootstrap/configuration.nix` first.
> The steps below are the original wipe-Arch plan, kept for reference.

The point of the host split is that the shared `modules/` and `home/` don't change, only the host does.

1. Boot the stick on the laptop, clone/copy the repo to `~/.dotfiles`.
2. **Decide the disk layout** (this is the real decision, see `TODO.md`). Current NVMe: Windows (BitLocker!) on p3/p4,
   Arch on p5 (/boot 1G) p6 (swap 32G) p7 (/ 650G). Sensible plan: reuse p5-p7 for NixOS (wipes Arch), keep Windows and the shared ESP (p1) untouched.
3. Create/format those partitions (by hand or a disko file; **do not let disko `destroy` the whole disk**).
4. With the new partitions mounted under `/mnt`:
   `nixos-generate-config --root /mnt --show-hardware-config > hosts/internal/hardware-configuration.nix`
5. `sudo nixos-install --flake ~/.dotfiles/nixos#internal`
6. Copy your data (`~/Documents`, `~/.ssh`, app state under `~/.config`) back from the old install. **Back up first.**

Before step 5 read the bootloader notes in `hosts/internal/default.nix` and `TODO.md` (shared ESP, Windows entry, `grub-reboot`).
