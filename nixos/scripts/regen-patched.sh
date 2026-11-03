#!/usr/bin/env bash
# Regenerate nixos/home/desktop/patched/ from the ORIGINAL Arch dotfiles.
#
# The originals (config/, arch/, zshrc, profile.sh) are never modified. This
# script copies the ones that cannot work unchanged on NixOS and applies a small,
# explicit set of sed rewrites. Re-run it whenever the originals drift.
#
# What gets rewritten, and why:
#   * `#!/bin/zsh` -> `#!/usr/bin/env zsh`   (NixOS has no /bin/zsh or /bin/bash)
#   * i3blocks state files ($HOME/.config/i3blocks/.toggle_*, caches, history)
#       -> ${XDG_STATE_HOME:-$HOME/.local/state}/i3blocks/
#     (on NixOS ~/.config/i3blocks is a read-only symlink into the store)
#   * i3 config: /home/val/... and ~/.dotfiles/arch/... -> ~/.config / ~/.local
#   * wallpaper.sh: no hardcoded DISPLAY/XAUTHORITY/user, default dir under $HOME
#
# zshrc and profile.sh are NOT patched: they handle NixOS themselves and are
# linked live (see home/common.nix and home/desktop/files.nix).
#
# Each rewrite is asserted, so upstream drift makes this script fail loudly
# instead of silently producing an unpatched file.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
out="$here/../home/desktop/patched"
case "$out" in */nixos/scripts/../home/desktop/patched) ;; *) echo "refusing odd out dir: $out" >&2; exit 1 ;; esac

STATE_DIR_EXPR='${XDG_STATE_HOME:-$HOME/.local/state}/i3blocks'

rm -rf "$out"
mkdir -p "$out/i3" "$out/i3blocks" "$out/dunst"

# copy <repo-relative file> <dest dir>  (tracked files only; keeps exec bit)
copy() { install -m "$(stat -c %a "$repo/$1")" "$repo/$1" "$2/"; }
assert() { # assert <file> <fixed string>
  grep -qF -- "$2" "$1" || { echo "expected rewrite missing in $1: $2" >&2; exit 1; }
}

# --- i3 -----------------------------------------------------------------------
git -C "$repo" ls-files config/i3 | while read -r f; do copy "$f" "$out/i3"; done
sed -i \
  -e 's|/home/val/\.config/i3/|~/.config/i3/|g' \
  -e 's|~/\.dotfiles/arch/wallpaper\.sh ~/\.dotfiles/arch/wallpapers|~/.local/bin/wallpaper.sh ~/.local/share/wallpapers|' \
  -e 's|~/\.dotfiles/arch/wallpapers/landscape|~/.local/share/wallpapers/landscape|g' \
  "$out/i3/config"
assert "$out/i3/config" '~/.config/i3/volume-change.sh'
assert "$out/i3/config" '~/.local/bin/wallpaper.sh ~/.local/share/wallpapers'
assert "$out/i3/config" '~/.local/share/wallpapers/landscape'
if grep -q '\.dotfiles\|/home/val' "$out/i3/config"; then echo "leftover hardcoded path in i3/config" >&2; exit 1; fi
for f in "$out"/i3/*; do
  sed -i -e '1s|^#!/bin/zsh$|#!/usr/bin/env zsh|' -e '1s|^#!/bin/bash$|#!/usr/bin/env bash|' "$f"
done

# --- i3blocks -----------------------------------------------------------------
git -C "$repo" ls-files config/i3blocks | grep -v '\.gitignore$' | while read -r f; do copy "$f" "$out/i3blocks"; done
for f in "$out"/i3blocks/*.sh; do
  sed -i \
    -e '1s|^#!/bin/zsh$|#!/usr/bin/env zsh|' \
    -e '1s|^#!/bin/bash$|#!/usr/bin/env bash|' \
    -e 's|"\$HOME/\.config/i3blocks/\.|"'"$STATE_DIR_EXPR"'/.|g' \
    -e 's|^STATE_DIR="\$HOME/\.config/i3blocks"$|STATE_DIR="'"$STATE_DIR_EXPR"'"|' \
    "$f"
  # make sure the state dir exists before first write
  if grep -qF 'XDG_STATE_HOME' "$f"; then
    sed -i '1a mkdir -p "'"$STATE_DIR_EXPR"'"' "$f"
  fi
done
assert "$out/i3blocks/battery.sh" 'XDG_STATE_HOME'
assert "$out/i3blocks/gpu_stats.sh" 'XDG_STATE_HOME'
assert "$out/i3blocks/network.sh" 'XDG_STATE_HOME'
# scripts (not state) must still be addressed in the (read-only) config dir:
assert "$out/i3blocks/gpu_usage.sh" '"$HOME/.config/i3blocks/gpu_stats.sh"'
assert "$out/i3blocks/battery.sh" '"$HOME/.config/i3blocks/battery_logic.sh"'

# --- dunst --------------------------------------------------------------------
copy config/dunst/dunst-sound.sh "$out/dunst"
sed -i '1s|^#!/bin/zsh$|#!/usr/bin/env zsh|' "$out/dunst/dunst-sound.sh"

# --- wallpaper ----------------------------------------------------------------
copy arch/wallpaper.sh "$out"
sed -i \
  -e '1s|^#!/bin/zsh$|#!/usr/bin/env zsh|' \
  -e 's|^export DISPLAY=:0$|export DISPLAY="${DISPLAY:-:0}"|' \
  -e 's|^export XAUTHORITY=/home/val/\.Xauthority$|export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"|' \
  -e 's|\${1:-/etc/systemd/system/wallpapers}|${1:-$HOME/.local/share/wallpapers}|' \
  "$out/wallpaper.sh"
assert "$out/wallpaper.sh" 'DISPLAY="${DISPLAY:-:0}"'
assert "$out/wallpaper.sh" '${1:-$HOME/.local/share/wallpapers}'

# --- syntax check ---------------------------------------------------------------
fail=0
for f in "$out"/i3/* "$out"/i3blocks/*.sh "$out"/dunst/*.sh "$out/wallpaper.sh"; do
  [ "$f" = "$out/i3/config" ] && continue
  case "$(head -n1 "$f")" in
    *zsh*) zsh -n "$f" || fail=1 ;;
    *bash*) bash -n "$f" || fail=1 ;;
  esac
done
[ "$fail" = 0 ] || { echo "syntax check failed" >&2; exit 1; }
echo "regenerated $out"
