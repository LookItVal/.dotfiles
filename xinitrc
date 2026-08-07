xrdb -merge ~/.Xresources
systemctl --user import-environment DISPLAY XAUTHORITY
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
fi
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP=i3
exec i3
