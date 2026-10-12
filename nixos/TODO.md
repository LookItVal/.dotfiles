# TODO / unverified / decisions

## 0. Honest status
**Nothing was evaluated, built, or booted.** Expect eval errors on first `nix flake check`.
Executed for real: `scripts/regen-patched.sh` (sed rewrites with assertions) and `bash -n`/`zsh -n` on the results.

## 1. Decisions needed from you
- [x] **Internal disk layout / bootloader.** Decided: keep Arch (shrink p7 to 450 GiB), new p8 for NixOS, systemd-boot on the shared Windows ESP (p1, `/efi`) with p5 retyped to XBOOTLDR (`/boot`), Arch as a systemd-boot `extraEntries` entry. Steps in `INSTALL.md`; config in `hosts/internal/default.nix`.
- [x] **Password.** The bootstrap install creates `val` with a real password, so `initialPassword` only matters for fresh `usb` installs. Optionally move to `hashedPasswordFile` later.
- [ ] **NVIDIA mode.** Defaults to PRIME *offload*. Your Arch external outputs are named `HDMI-1-0`/`DP-2`, which suggests they hang off the dGPU. If external monitors misbehave, set `my.nvidia.primeMode = "sync"` (`modules/nvidia.nix`).
- [ ] **Fonts.** Curated set by default; `my.fonts.allNerdFonts = true` installs all ~80 (large).
- [ ] **Keep both docker and podman?** Both enabled. Podman is required (lerd, see `modules/lerd.nix`); docker only if something still needs it.
- [ ] **autologin on all VTs.** `services.getty.autologinUser` isn't tty1-only like the Arch drop-in; I added `autologinOnce = true` so only the first login after boot is automatic.
- [ ] **stateVersion** is `26.05` in `modules/base.nix` and `home/default.nix`: set it to what the installer generates for the first install.

## 2. Spots I don't trust (API names from memory)
- `services.xserver.displayManager.startx.enable`: may have moved/renamed; fallback is LightDM autologin or a `startx` wrapper.
- `services.getty.autologinOnce`, `programs.i3lock.{enable,package}`, `programs.xfconf`, `programs.thunar.plugins` (`pkgs.xfce.*` scope), `programs.firefox.nativeMessagingHosts.packages`.
- `hardware.nvidia.package = ...nvidiaPackages.latest` + `linuxPackages_latest`: kernel/driver combo for Blackwell; if the module doesn't build use `pkgs.linuxPackages` (LTS) or `nvidiaPackages.beta`. `powerManagement.finegrained` on Blackwell: untested.
- home-manager: `programs.git.settings.*` (recent rename from `userName/userEmail`), `programs.gh.gitCredentialHelper`, `xdg.userDirs.*`, `systemd.user.{services,timers}`.
- `xpkg` helper (flake.nix) assumes either `pkgs.<tool>` or `pkgs.xorg.<tool>` exists for xrandr/xrdb/xset/...
- disko: `extraArgs` for labels, and that generated `fileSystems` use `by-partlabel` (portable). Check `nixos-generate-config` output vs disko if root doesn't mount.
- `catppuccin-gtk` may no longer exist in nixpkgs (guarded, warns). Then the GTK theme in `gtk-3.0/settings.ini` won't resolve; consider the `catppuccin/nix` flake.
- Packages via `maybe` (warn if missing): `redisinsight`, `fontpreview`, `catppuccin-papirus-folders`.
- `_0xproto`, `_3270`, `ia-writer`, `m+` Nerd Font attr names (only matter if you hand-pick fonts; the `allNerdFonts` path doesn't depend on names).

## 3. Behavioural differences to check once it boots
- [ ] i3 monitor names (`DP-2`, `eDP-1`, `HDMI-1-0`): may differ under NixOS's X config; workspace→output pinning and autorandr profiles depend on them.
- [ ] `picom` `backend = "glx"` with NVIDIA PRIME offload; new `rules:` syntax needs picom ≥ 12.
- [ ] `exec i3lock ... ` at i3 start relies on PAM `i3lock` service (provided by `programs.i3lock`).
- [ ] Wallpapers: the systemd *user* timer needs `DISPLAY`/`XAUTHORITY` from `~/.xinitrc`'s `import-environment`; i3's `exec_always` also runs the script at start.
- [ ] i3blocks state moved to `~/.local/state/i3blocks/`. Toggle state from Arch won't carry over.
- [ ] `dbus-launch` availability in `.xinitrc` (NixOS normally has a user bus already; the script only starts one if `DBUS_SESSION_BUS_ADDRESS` is unset).
- [ ] `zim` installs itself over the network into `~/.config/zsh/zim` on first shell; offline first boot gives errors but not a broken shell.
- [ ] `alias l='exa'` was broken on Arch (only `eza` is installed); patched copy uses `eza`. The zim `exa` module in `.zimrc` is probably a no-op: swap for an `eza` setup if you care.
- [ ] `reboot-windows` (used by the i3blocks power menu) is patched to `systemctl reboot --boot-loader-entry=auto-windows` (systemd-boot one-shot). Check it works without sudo. The Arch `zshrc` still uses `grub-reboot`: switch it once GRUB is removed from Arch.
- [ ] lerd: `.test` DNS via NetworkManager's dnsmasq (`modules/lerd.nix`) with Tailscale also managing `/etc/resolv.conf`. Verify with `lerd dns:check`. `lerd install` may try to write `/etc/NetworkManager/dnsmasq.d/lerd.conf`, which NixOS now owns (read-only symlink).
- [ ] lerd's generated `lerd-app-*` user services hardcode `PATH=...:/usr/bin:/bin`. On NixOS, non-PHP proxy commands (e.g. nabu's `go run`) need `/run/current-system/sw/bin/nix develop .. --command ...` or an absolute path.
- [ ] Touchpad (tap-to-click, natural scroll) and keyboard settings from Arch aren't captured anywhere in the repo: set `services.libinput.touchpad.*`.
- [ ] `QT_USE_PORTAL=1 flameshot gui` / `useX11LegacyScreenshot` and the portals: only checked on paper.
- [ ] `pactl`/`paplay` come from `pkgs.pulseaudio` (client tools), server is pipewire-pulse.

## 4. Not ported (on purpose; see INVENTORY.md §1)
spicetify theming, mutable app configs (htoprc, flameshot.ini, pavucontrol.ini, kdeglobals, QtProject.conf, trashrc, nwg-look), neofetch, `init/*` bootstrap scripts, claude-desktop, nvm, per-app state in `~/.config`.

## 5. Nice later
- Convert linked files to native HM modules (`programs.alacritty`, `services.dunst`, `programs.rofi`, `services.picom`, `xsession.windowManager.i3`) so colours can be shared from one catppuccin palette.
- `spicetify-nix`, catppuccin/nix for GTK/icons/GRUB themes (Arch had the catppuccin GRUB theme).
- Wrap scripts with `writeShellApplication` so their runtime deps are pinned instead of relying on the system PATH.
- Secure Boot (lanzaboote) if you move to systemd-boot.
- CI-less sanity: `nix flake check` + `nixos-rebuild build-vm --flake ./nixos#usb` (VM test needs no hardware).
