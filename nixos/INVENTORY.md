# Inventory: Arch setup -> NixOS

Generated from `pacman -Qqe` (232 explicitly installed), `pacman -Qqm` (AUR/foreign),
`git ls-files`, and the live system (`lspci`, `lsblk`, `/etc/X11`, `mkinitcpio.conf`,
kernel cmdline). **Nothing here was evaluated** (Nix isn't installed); nixpkgs names are
from memory. Confidence: ✓ confident, ~ probably right, ? guess / may have been renamed.

## 1. Repo files and how they're handled

| Repo file | NixOS handling | Notes |
|---|---|---|
| `config/i3/config` | **patched copy** `home/patched/i3/config` -> `~/.config/i3` | `/home/val` and `~/.dotfiles/arch/...` paths rewritten. Monitor names `DP-2`/`eDP-1`/`HDMI-1-0` kept, may differ under NixOS PRIME (see TODO). |
| `config/i3/*.sh`, `take-ss`, `record-screen` | patched copy (zsh shebangs -> `env`) | `take-ss`/`record-screen` were already `env bash`, unchanged otherwise. Need `file`, `maim`, `xdotool`, `xclip`, `ffmpeg`, `jq`, `libnotify`. |
| `config/i3blocks/*` | **patched copy** | State files (`.toggle_*`, caches, battery history) moved from `~/.config/i3blocks/` to `~/.local/state/i3blocks/` because the config dir is a read-only store link. |
| `config/dunst/dunstrc`, `sounds/` | linked as-is | |
| `config/dunst/dunst-sound.sh` | patched copy (shebang) | needs `paplay` (pkgs.pulseaudio) |
| `config/picom/picom.conf` | linked as-is | Uses the new `rules:` syntax; needs a recent picom (nixpkgs' should be fine, verify). `backend = "glx"` with NVIDIA PRIME: verify. |
| `config/rofi/*` | linked as-is | |
| `config/alacritty/*` | linked as-is | contains a stray tracked `.bak` file, harmless |
| `config/fastfetch/*` | linked as-is | still the Arch ASCII logo |
| `config/autorandr/*` | linked as-is | **Only tracked profiles are visible to the flake**; `double-2k-vertical`, `single-secondary`, `single-vertical`, `triple` are currently *untracked*. autorandr can't `--save` into the read-only link. |
| `config/networkmanager-dmenu/config.ini` | linked as-is | |
| `config/xsettingsd/xsettingsd.conf` | linked as-is | xsettingsd isn't started by anything in the i3 config (same as Arch) |
| `config/gtk-3.0/settings.ini` | linked as-is | theme `catppuccin-macchiato-mauve-standard+default` must exist (see catppuccin-gtk below) |
| `config/tmux/tmux.conf` | linked as-is | needs tpm cloned to `~/.tmux/plugins/tpm` to do anything |
| `config/zsh/.zimrc`, `modules/` | linked as-is | zim itself is downloaded at first shell start (needs `curl` + network) |
| `config/nvim/*` | **live symlink** to `~/.dotfiles/config/nvim` | lazy.nvim writes into the config dir; repo must live at `~/.dotfiles` |
| `config/git/config` | replaced by `programs.git` + `programs.gh` | original hardcoded `/usr/bin/gh` |
| `config/mimeapps.list` | `xdg.mimeApps` in `home/default.nix` | |
| `config/user-dirs.dirs` | `xdg.userDirs` | |
| `config/xdg-desktop-portal/portals.conf` | `xdg.portal` in `modules/desktop-i3.nix` | original section header is misspelled `[preffered]` so it probably never worked as intended |
| `zshrc` | **patched copy** -> `~/.zshrc` | nixos treated like arch (no tmux auto-attach); `/home/val` -> `$HOME`; `alias l='exa'` -> `eza` |
| `profile.sh` | **patched copy** -> `~/.zprofile` | `exec startx` on tty1 also for `nixos` |
| `xinitrc` | linked as-is -> `~/.xinitrc` | needs `xrdb`, `dbus-launch`, `dbus-update-activation-environment` on PATH |
| `arch/wallpaper.sh` | **patched copy** -> `~/.local/bin/wallpaper.sh` | no hardcoded DISPLAY/XAUTHORITY/user |
| `arch/wallpaper.service` + `.timer` | `systemd.user.services/timers.wallpaper` (`home/wallpaper.nix`) | was a *system* unit under `/etc/systemd/system`; now a user unit |
| `arch/wallpapers/` (285 MB) | linked -> `~/.local/share/wallpapers` | `portrait/` is currently **untracked** -> invisible to the flake until `git add`ed |
| `arch/autologin.conf` | `services.getty.autologinUser` (+`autologinOnce`) | Arch autologged in on tty1 only; NixOS option applies to all VTs |
| `init.sh`, `init/*` | **not ported** | pacman/yay/grub/spicetify bootstrap; superseded by the flake. Mac/ubuntu parts irrelevant. |
| `config/spicetify/*` | **not ported** | spicetify patches the installed Spotify in place, which can't work on the read-only store. Use the `spicetify-nix` flake later. |
| `config/neofetch/*` | not ported | replaced by fastfetch long ago |
| `config/{kdeglobals,QtProject.conf,htop/htoprc,pavucontrol.ini,trashrc,nwg-look,flameshot/flameshot.ini,Maui,arkrc,config,nextjs-nodejs}` | **not ported** | mutable app state, written by the apps themselves (read-only links would break saving). `flameshot.ini` also hardcodes a project path. Seed them by hand if you miss them. |
| *(not in repo)* `~/.xbindkeysrc` | inlined in `home/files.nix` | mouse buttons 8/9 -> Delete/Return via xdotool |
| `/etc/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf` | handled by `hardware.nvidia` | |
| mkinitcpio `MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)` + cmdline `nvidia_drm.modeset=1 nvidia_drm.fbdev=1` | `modesetting.enable` + `boot.kernelParams` | early-KMS initrd modules not replicated (usually unnecessary on NixOS) |

## 2. Hardware (from the live system)

- HP OMEN Slim Gaming Laptop 16-an0xxx, hostname `QUINN-OMEN`
- `0000:00:02.0` Intel Arrow Lake-P iGPU -> `PCI:0:2:0`
- `0000:01:00.0` NVIDIA GB206M RTX 5070 Max-Q -> `PCI:1:0:0`
- Internal NVMe (953.9 G): p1 ESP `SYSTEM` 512M, p2 16M (MSR), **p3 BitLocker Windows 268.9G**, p4 Windows RE, **p5 Arch `/boot` 1G vfat**, p6 swap 32G, **p7 Arch `/` 650.6G ext4**
- Keymap `us`, locale `en_US.UTF-8`, TZ `US/Central`

## 3. Packages: explicitly installed natively (`pacman -Qqe`, non-AUR)

### Handled by NixOS options / modules (no package needed)

| Arch | NixOS |
|---|---|
| base, base-devel, sudo, linux | (implicit), `security.sudo`, `boot.kernelPackages = linuxPackages_latest` ✓ |
| linux-firmware, linux-firmware-marvell, sof-firmware | `hardware.enableRedistributableFirmware`, `hardware.firmware = [ sof-firmware ]` ✓ |
| intel-ucode | `hardware.cpu.intel.updateMicrocode` ✓ |
| grub, efibootmgr, os-prober | `boot.loader.grub.*` (`useOSProber`), `efibootmgr` pkg ✓ |
| networkmanager, dnsmasq, networkmanager-dispatcher-ntpd, ntp | `networking.networkmanager.enable`; time sync is `systemd-timesyncd` by default ✓ (dnsmasq not needed; NM spawns its own) |
| bluez, bluez-utils | `hardware.bluetooth.enable` ✓ |
| pipewire-pulse, pipewire-docs | `services.pipewire.pulse.enable` ✓ (docs skipped) |
| nvidia-open, nvidia-utils, nvidia-prime | `hardware.nvidia` (open + PRIME), `modules/nvidia.nix` ✓ |
| docker, docker-compose | `virtualisation.docker.enable` ✓ + `docker-compose` pkg ✓ |
| podman | `virtualisation.podman.enable` ✓ |
| tailscale | `services.tailscale.enable` ✓ |
| cronie | `services.cron` (left off; nothing uses it) |
| gvfs | `services.gvfs.enable` ✓ |
| man-db, man-pages | `documentation.man/dev.enable` ✓ |
| ntfs-3g | `boot.supportedFilesystems = [ "ntfs" ]` ✓ |
| xorg-server, xorg-xinit, xorg-xwayland, xorg-server-{common,devel,src,xephyr,xnest,xvfb} | `services.xserver.enable`, `displayManager.startx` ~; devel/src/xephyr/xnest/xvfb dropped |
| i3-wm | `services.xserver.windowManager.i3` ✓ |
| thunar, thunar-archive-plugin, thunar-volman | `programs.thunar` + `plugins` ~ (`pkgs.xfce.*` scope may have been flattened) |
| firefox, firefoxpwa | `programs.firefox` + `nativeMessagingHosts.packages` ~ |

### Plain packages

| Arch | nixpkgs | |
|---|---|---|
| 7zip | `_7zz` | ~ (`7zip`/`p7zip` may also exist) |
| alacritty, autorandr, bat, dunst, eza, fastfetch, fd, feh, flameshot, fzf, git, gimp, htop, i3blocks, i3status, inkscape, jq, maim, neovim, nodejs, obsidian, picom, ripgrep, rofi, vlc, xarchiver, xbindkeys, xclip, xdotool, xsel, xss-lock, zip, zsh, guvcview, texinfo, unzip | same name | ✓ (`gimp` may now be gimp 3.x; `xarchiver` ✓) |
| bind | `bind` | ✓ (provides dig) |
| bluetui | `bluetui` | ✓ |
| brightnessctl | `brightnessctl` (+ udev rule via `services.udev.packages`) | ✓ |
| github-cli | `gh` | ✓ (`programs.gh`) |
| ipython | `python3Packages.ipython` | ✓ |
| python-pip | `python3Packages.pip` | ✓ |
| libreoffice-still | `libreoffice-still` | ✓ |
| magic-wormhole | `magic-wormhole` | ✓ |
| mariadb-clients | `mariadb.client` | ~ |
| moonlight-qt | `moonlight-qt` | ✓ |
| npm | bundled with `nodejs` | ✓ |
| nvm | none (shell script) — use `nodejs`, `fnm`, or per-project devShells | ✗ |
| nvtop | `nvtopPackages.full` | ✓ |
| composer, php | `phpPackages.composer`, `php` | ✓ |
| papirus-icon-theme | `papirus-icon-theme` | ✓ |
| unrar | `unrar` (unfree) | ✓ |
| vlc-plugins-all | included in `vlc` | ✓ |
| xorg-xrandr/xrdb/xset/xsetroot/xinput/xprop/xev/xwininfo/xhost/setxkbmap/xmodmap | `xrandr` etc. (fallback `xorg.<name>`), via `xpkg` helper | ~ naming in flux |
| other xorg-* (xorg-docs, fonts-*, bdftopcf, mkfontscale, x11perf, iceauth, sessreg, smproxy, xcmsdb, xcursorgen, xdpyinfo, xdriinfo, xgamma, xkbcomp/xkbevd/xkbutils, xlsatoms/xlsclients, xpr, xrefresh, xvinfo, xwd, xwud, xauth, xbacklight, xf86-video-vesa) | not installed | these were dependency-ish leftovers; add by hand if missed. `xorg-xbacklight` -> `acpilight` if wanted |
| catppuccin-gtk-theme-macchiato (AUR) | `catppuccin-gtk.override { accents=["mauve"]; variant="macchiato"; size="standard"; }` | ? upstream archived; nixpkgs may have dropped it. Guarded by `pkgs ? catppuccin-gtk`. |
| i3lock-color (AUR) | `i3lock-color` via `programs.i3lock.package` | ✓ |

## 4. Packages: AUR / foreign (`pacman -Qqm`)

| Arch (AUR) | nixpkgs | |
|---|---|---|
| claude-code | `claude-code` (unfree) | ✓ |
| claude-desktop | **none official** | ✗ community flakes exist (e.g. `k3d3/claude-desktop-linux-flake`); not wired in |
| cursor-bin | `code-cursor` (unfree) | ✓ |
| visual-studio-code-bin | `vscode` (unfree) | ✓ |
| google-chrome | `google-chrome` (unfree) | ✓ |
| slack-desktop | `slack` (unfree) | ✓ |
| figma-linux | `figma-linux` | ~ |
| fontpreview | `fontpreview` | ? guarded with `maybe` |
| networkmanager-dmenu-git | `networkmanager_dmenu` | ✓ (not -git, so slightly older) |
| networkmanager-dispatcher-ntpd | n/a | ✗ not needed (timesyncd) |
| papirus-folders-catppuccin-git | `catppuccin-papirus-folders` (override flavor/accent) | ? added via `maybe`, un-overridden; `papirus-folders` run isn't replicated |
| ps_mem | `ps_mem` | ✓ |
| pwvucontrol | `pwvucontrol` | ✓ |
| redisinsight | `redisinsight` | ? guarded with `maybe` |
| spicetify-cli | `spicetify-cli` | ✓ (theming itself not ported) |
| spotify-launcher (repo) | `spotify` (unfree) | ✓ |
| yay | n/a | ✗ |
| i3lock-color-debug, pwvucontrol-debug, redisinsight-debug, spicetify-cli-debug, yay-debug, reproc, reproc-debug | n/a | build leftovers |

## 5. Fonts (~80 `ttf-*-nerd` / `otf-*-nerd` packages)

nixpkgs ≥ 25.05 has one attr per family: `nerd-fonts.<name>`.

| Arch | `nerd-fonts.` | | Arch | `nerd-fonts.` | |
|---|---|---|---|---|---|
| ttf-0xproto-nerd | `_0xproto` | ? | ttf-iosevkaterm-nerd | `iosevka-term` | ✓ |
| ttf-3270-nerd | `_3270` | ? | ttf-iosevkatermslab-nerd | `iosevka-term-slab` | ✓ |
| ttf-adwaitamono-nerd | `adwaita-mono` | ? | ttf-jetbrains-mono(-nerd) | `jetbrains-mono` (+ `pkgs.jetbrains-mono`) | ✓ |
| ttf-agave-nerd | `agave` | ✓ | ttf-lekton-nerd | `lekton` | ✓ |
| ttf-anonymouspro-nerd | `anonymice` | ✓ | ttf-liberation-mono-nerd | `liberation` | ✓ |
| ttf-arimo-nerd | `arimo` | ✓ | ttf-lilex-nerd | `lilex` | ✓ |
| ttf-bigblueterminal-nerd | `bigblue-terminal` | ✓ | ttf-martian-mono-nerd | `martian-mono` | ✓ |
| ttf-bitstream-vera-mono-nerd | `bitstream-vera-sans-mono` | ✓ | ttf-meslo-nerd | `meslo-lg` | ✓ |
| ttf-cascadia-code-nerd | `caskaydia-cove` | ✓ | ttf-monofur-nerd | `monofur` | ✓ |
| ttf-cascadia-mono-nerd | `caskaydia-mono` | ✓ | ttf-monoid-nerd | `monoid` | ✓ |
| ttf-cousine-nerd | `cousine` | ✓ | ttf-mononoki-nerd | `mononoki` | ✓ |
| ttf-d2coding-nerd | `d2coding` | ✓ | ttf-mplus-nerd | `m+` | ? |
| ttf-daddytime-mono-nerd | `daddy-time-mono` | ✓ | ttf-nerd-fonts-symbols(-mono) | `symbols-only` | ✓ |
| ttf-dejavu-nerd | `dejavu-sans-mono` | ✓ | ttf-noto-nerd | `noto` | ✓ |
| ttf-envycoder-nerd | `envy-code-r` | ✓ | ttf-profont-nerd | `profont` | ✓ |
| ttf-fantasque-nerd | `fantasque-sans-mono` | ✓ | ttf-proggyclean-nerd | `proggy-clean-tt` | ✓ |
| ttf-firacode-nerd | `fira-code` | ✓ | ttf-recursive-nerd | `recursive-mono` | ✓ |
| ttf-go-nerd | `go-mono` | ✓ | ttf-roboto-mono-nerd | `roboto-mono` | ✓ |
| ttf-gohu-nerd | `gohufont` | ✓ | ttf-sharetech-mono-nerd | `sharetech-mono` | ✓ |
| ttf-hack-nerd | `hack` | ✓ | ttf-sourcecodepro-nerd | `sauce-code-pro` | ✓ |
| ttf-heavydata-nerd | `heavy-data` | ✓ | ttf-space-mono-nerd | `space-mono` | ✓ |
| ttf-iawriter-nerd | `ia-writer`? | ? | ttf-terminus-nerd | `terminess-ttf` | ✓ |
| ttf-ibmplex-mono-nerd | `blex-mono` | ✓ | ttf-tinos-nerd | `tinos` | ✓ |
| ttf-inconsolata(-go,-lgc)-nerd | `inconsolata`, `inconsolata-go`, `inconsolata-lgc` | ✓ | ttf-ubuntu-nerd / -mono | `ubuntu`, `ubuntu-mono` | ✓ |
| ttf-intone-nerd | `intone-mono` | ✓ | ttf-victor-mono-nerd | `victor-mono` | ✓ |
| ttf-iosevka-nerd | `iosevka` | ✓ | ttf-zed-mono-nerd | `zed-mono` | ✓ |
| otf-atkinsonhyperlegiblemono-nerd | `atkynson-mono` | ✓ | otf-hasklig-nerd | `hasklug` | ✓ |
| otf-aurulent-nerd | `aurulent-sans-mono` | ✓ | otf-hermit-nerd | `hurmit` | ✓ |
| otf-codenewroman-nerd | `code-new-roman` | ✓ | otf-monaspace-nerd | `monaspace` | ✓ |
| otf-comicshanns-nerd | `comic-shanns-mono` | ✓ | otf-opendyslexic-nerd | `open-dyslexic` | ✓ |
| otf-commit-mono-nerd | `commit-mono` | ✓ | otf-overpass-nerd | `overpass` | ✓ |
| otf-droid-nerd | `droid-sans-mono` | ✓ | otf-firamono-nerd | `fira-mono` | ✓ |
| otf-geist-mono-nerd | `geist-mono` | ✓ | | | |

`modules/fonts.nix` installs a curated subset by default (everything the configs
actually reference: FiraCode, Fira Mono, Hack + favourites) and `my.fonts.allNerdFonts = true`
installs every Nerd Font via `attrValues pkgs.nerd-fonts`, so none of the per-font attr names above
need to be right for that path.

## 6. Likely no clean nixpkgs equivalent

- **claude-desktop** (no official Linux build; community flake)
- **nvm** (use nodejs/fnm/devshells)
- **spicetify theming** (needs `spicetify-nix` or similar; in-place patching can't work on NixOS)
- **papirus-folders recolouring** (catppuccin variant via an override, not verified)
- **catppuccin-gtk** (possibly dropped from nixpkgs; theme could be supplied via `pkgs.catppuccin-gtk` older rev or `catppuccin/nix`)
- **yay / pacman / AUR** by definition
- **lerd** (in `zshrc`/`config/lerd`, installed outside pacman into `~/.local`; not inventoried: it's a downloaded binary installer, may need `nix-ld`)
- **RedisInsight, Figma-linux, fontpreview** — exist in nixpkgs as far as I remember but unverified

## 7. Things on the system that aren't in the repo or pacman list

`~/.config/` contains app state for Cursor, Code, Claude, Slack, Obsidian, Chrome, GIMP, Inkscape,
LibreOffice, mozilla, spotify, shopify-cli, … (mostly git-ignored in `config/.gitignore`).
Those are per-app user data, not dotfiles; migrate by copying `~/.config`/`~/.local/share`
selectively, not through this flake.
