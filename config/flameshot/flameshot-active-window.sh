#!/usr/bin/env bash

# Query i3 tree for the focused window's container geometry AND its output's position
read -r W H X Y MX MY INDEX <<< $(i3-msg -t get_tree | jq -r '
  recurse(.nodes[], .floating_nodes[]) | 
  select(.focused) as $win | 
  .. | select(.nodes?[]?.id == $win.id or .floating_nodes?[]?.id == $win.id) | select(.type == "output") as $out |
  "\($win.rect.width) \($win.rect.height) \($win.rect.x) \($win.rect.y) \($out.rect.x) \($out.rect.y)"
')

# Calculate relative coordinates for Flameshot
REL_X=$((X - MX))
REL_Y=$((Y - MY))

# Pass relative geometry to flameshot screen
flameshot screen --region "${W}x${H}+${REL_X}+${REL_Y}"
notify-send "Flameshot" "Captured window (${W}x${H} at +${REL_X}+${REL_Y})"