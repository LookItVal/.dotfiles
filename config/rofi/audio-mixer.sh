#!/usr/bin/env zsh
# Rofi audio mixer (script mode: stays open, rows re-render in place).
#   OUTPUT        every available sink; ● marks where audio goes now.
#   APPLICATIONS  notification level + each playing app stream.
#   Left/Right ∓5%   Shift+Left/Right ∓1%   Enter: switch output / mute app   Alt+m mute
# Switching to a network speaker (Sonos etc.) needs Enter twice, so it can't blast a room by accident.
# Notifications aren't a live stream, so that row is a stored level applied by dunst-sound.sh.

nstate="${XDG_STATE_HOME:-$HOME/.local/state}/notif-volume"
sstate="${XDG_STATE_HOME:-$HOME/.local/state}/notif-sink"
armfile="${XDG_RUNTIME_DIR:-/tmp}/mixer-armed"
sounds="$HOME/.config/dunst/sounds"

if [[ -z $ROFI_RETV ]]; then
    exec rofi -show mixer -modi "mixer:${0:A}" -no-sort -no-show-icons -selected-row 1 \
        -kb-move-char-back "Control+b" -kb-move-char-forward "Control+f" \
        -kb-mode-next "" -kb-mode-previous "" \
        -kb-custom-1 "Left" -kb-custom-2 "Right" \
        -kb-custom-3 "Shift+Left" -kb-custom-4 "Shift+Right" -kb-custom-5 "m,Alt+m" -kb-custom-6 "Up" -kb-custom-7 "Down" -kb-custom-8 "Tab" -kb-custom-9 "ISO_Left_Tab" \
        -kb-element-next "" -kb-element-prev "" \
        -kb-row-up "Control+p" -kb-row-down "Control+n" \
        -theme-str '* {font: "FiraCode Nerd Font Mono 12";} window {width: 100ch;}
                    message {border: 0 0 1px 0; border-color: #494d64; padding: 2px 0 10px 8px; margin: 0 0 6px 0;}
                    listview {border: 0; padding: 0;}
                    mainbox {children: [message, listview];}
                    listview {lines: 16; dynamic: true; fixed-height: false; spacing: 4px;}'
fi

mkdir -p "${nstate:h}"
[[ -f $nstate ]] || print 100 >"$nstate"
ndev=(); [[ -f $sstate && "$(<$sstate)" != auto ]] && pactl list short sinks | cut -f2 | grep -qxF -- "$(<$sstate)" && ndev=(--device="$(<$sstate)")
clamp() { (( $1 < 0 )) && print 0 || { (( $1 > 100 )) && print 100 || print $1 } }

# ---- colours: same USAGE_STOPS gradient as the usage popup (low = cool, 100 = mauve) ----
typeset -a color
color=( ${(f)"$(bash -c '
  src="$HOME/.config/claude/statusline.sh"
  eval "$(grep -E "^[A-Z]+=\"[0-9]+;[0-9]+;[0-9]+\"" "$src")"
  eval "$(sed -n "/^USAGE_STOPS=(/,/^)/p" "$src")"
  eval "$(sed -n "/^usage_color() {/,/^}/p" "$src")"
  for p in $(seq 0 100); do IFS=";" read -r r g b <<<"$(usage_color $p)"; printf "#%02x%02x%02x\n" $r $g $b; done')"} )
DIM="#494d64"; SUB="#6e738d"; RED="#ed8796"; MAUVE="#c6a0f6"; YEL="#eed49f"

I_NET=$'\U000F04C3'; I_BT=$'\U000F02CB'; I_HDMI=$'\U000F0379'; I_LAP=$'\U000F0322'; I_OUT=$'\U000F057E'
I_BELL=$'\U000F009A'; I_WEB=$'\U000F0239'; I_SPOT=$'\U000F04C7'; I_MUS=$'\U000F075A'; I_DISC=$'\U000F066F'; I_VID=$'\U000F0567'

# kind \t id \t class \t name \t pct \t muted \t active \t route-name \t route-sink
collect() {
    local def sinks; def="$(pactl get-default-sink)"; sinks="$(pactl -f json list sinks)"
    local fname='def fname: if (.name|test("^raop_")) then .description
             elif (.name|test("Speaker__sink")) then "Laptop Speakers"
             elif (.description|test("\\[[^]]+\\]")) then (.description|capture("\\[(?<m>[^]]+)\\]").m)
             else .description end;'
    print -r -- "$sinks" | jq -r --arg d "$def" "$fname"'.[]
        | select(((.active_port as $a | [.ports[]? | select(.name==$a) | .availability][0]) // "") != "not available")
        | [ "sink", .name,
            (if (.name|test("^raop_")) then "net" elif (.name|test("bluez")) then "bt"
             elif (.name|test("hdmi|HDMI")) then "hdmi" else "laptop" end),
            fname,
            (.volume|to_entries[0].value.value_percent|rtrimstr("%")), .mute, (.name==$d), "-", "-" ] | @tsv'
    local pin="auto" nrt nrs
    [[ -f $sstate ]] && pin="$(<$sstate)"
    nrt="$(print -r -- "$sinks" | jq -r --arg p "$pin" --arg d "$def" "$fname"'
        ([.[] | select(.name==$p)][0]) as $o | if $o then ($o|fname) else
        (([.[] | select(.name==$d)][0]) | fname) + " (auto)" end')"
    nrs="$pin"; [[ $nrs == auto || -z $nrs ]] && nrs=auto
    printf 'notif\t-\tnotif\tNotifications\t%s\tfalse\tfalse\t%s\t%s\n' "$(<$nstate)" "$nrt" "$nrs"
    pactl -f json list sink-inputs | jq -r --argjson s "$sinks" "$fname"'.[]
        | select([.properties["application.process.binary"], .properties["application.name"]] | any(. == "paplay" or . == "pacat") | not)
        | .sink as $si | ([$s[] | select(.index == $si)][0]) as $o
        | ["in", (.index|tostring),
           ((.properties["application.name"] // .properties["application.process.binary"] // "stream") | ascii_downcase),
           ((.properties["application.name"] // .properties["application.process.binary"] // "stream")
            + (if .properties["media.name"] then " · " + (.properties["media.name"]|.[0:22]) else "" end)),
           (.volume|to_entries[0].value.value_percent|rtrimstr("%")), .mute, false,
           (if $o then ($o|fname) else "-" end), (if $o then $o.name else "-" end)] | @tsv'
    # Open apps with no stream yet: PipeWire clients we don't already show. They will play to the default sink.
    local live; live="$(pactl -f json list sink-inputs | jq -r '[.[].properties["application.name"] // empty | ascii_downcase] | join("|")')"
    local dname; dname="$(print -r -- "$sinks" | jq -r --arg d "$def" "$fname"'.[] | select(.name==$d) | fname')"
    pw-dump | jq -r --arg live "$live" --arg dn "$dname" '
        [ .[] | select(.type=="PipeWire:Interface:Client") | .info.props
          | select(.["application.name"] != null)
          | select((.["application.process.binary"] // "") | test("^(wireplumber|pipewire.*|xdg-desktop-portal.*|pw-.*|pavucontrol|pwvucontrol|paplay|pacat|rofi)$") | not)
          | select(((.["application.name"] // "") | test("^(WirePlumber|pipewire)")) | not)
          | .["application.name"] ] | unique[]
        | select((ascii_downcase) as $n | ($live | split("|") | index($n)) | not)
        | ["idle", ., (ascii_downcase), ., "0", "false", "false", $dn, "-"] | @tsv'
}

esc() { print -rn -- "$1" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g'; }

# Fader: heavy line for the level (half-cell resolution via ╸), thin line for the rest of the track.
BAR=28
fader() { # pct muted
    local p=$1 on u f h
    (( p > 100 )) && p=100
    on=${color[$(( p + 1 ))]}; [[ $2 == true ]] && on=$SUB
    u=$(( (p * BAR * 2 + 50) / 100 )); f=$(( u / 2 )); h=$(( u % 2 ))
    print -rn -- "<span foreground='$on'>${(l:f::━:)}$( (( h )) && print -rn ╸ )</span><span foreground='$DIM'>${(l:$(( BAR - f - h ))::─:)}</span>"
}

appicon() {
    case $1 in
        notif) print -rn $I_BELL ;; *firefox*|*chrom*|*zen*) print -rn $I_WEB ;; *spotify*) print -rn $I_SPOT ;;
        *discord*|*vesktop*) print -rn $I_DISC ;; *mpv*|*vlc*) print -rn $I_VID ;; *) print -rn $I_MUS ;;
    esac
}

# Model: parallel arrays, one entry per rendered row
typeset -a rtext rinfo rsel
addrow() { rtext+=("$1"); rinfo+=("$2"); rsel+=("$3"); }   # text info selectable(1/0)

rowtext() { # marker icon name pct muted route
    local tag="      " rt=""
    [[ $5 == true ]] && tag="<span foreground='$RED'> muted</span>"
    [[ -n $6 && $6 != - ]] && rt="  <span foreground='$SUB'>→ $(esc "${6[1,24]}")</span>"
    printf '%s  %s  %s %s %4s%%%s%s' "$1" "$2" "$(esc "${(r:22:)3[1,22]}")" "$(fader $4 $5)" "$4" "$tag" "$rt"
}
idletext() { # icon name route
    printf "<span foreground='%s'>   %s  %s %s  idle        → %s</span>" "$SUB" "$1" "$(esc "${(r:22:)2[1,22]}")" "${(r:28::╌:)}" "$(esc "${3[1,18]}")"
}
header() { addrow "<span foreground='$SUB' weight='bold' size='small'>$1</span> <span foreground='$DIM'>${(l:56::─:)}</span>" hdr:- 0; }
spacer() { addrow "<span size='x-small'> </span>" hdr:- 0; }

build() {
    local msg='←/→ ∓5%   shift ∓1%   ⏎ set output   m mute   ⇥ route   esc close'
    if [[ -f $armfile ]]; then
        local an at; read -r an at <"$armfile"
        (( EPOCHSECONDS - at < 6 )) && msg="<span foreground='$YEL'>Press again to send audio to a network speaker</span>"
    fi
    MSG=$msg
    local k id cls name pct mute act rname rsink mk icon sec=""
    while IFS=$'\t' read -r k id cls name pct mute act rname rsink; do
        if [[ $k == sink && $sec != out ]]; then header OUTPUT; sec=out; fi
        if [[ $k != sink && $sec != app ]]; then [[ -n $sec ]] && spacer; header APPLICATIONS; sec=app; fi
        if [[ $k == idle ]]; then
            addrow "$(idletext "$(appicon $cls)" "$name" "$rname")" "idle:$id" 0
        elif [[ $k == sink ]]; then
            case $cls in net) icon=$I_NET;; bt) icon=$I_BT;; hdmi) icon=$I_HDMI;; *) icon=$I_LAP;; esac
            [[ $act == true ]] && mk="<span foreground='$MAUVE'>●</span>" || mk="<span foreground='$DIM'>○</span>"
            addrow "$(rowtext "$mk" "$icon" "$name" $pct $mute)" "sink:$id" 1
        else
            addrow "$(rowtext " " "$(appicon $cls)" "$name" $pct $mute "$rname")" "$k:$id" 1
        fi
    done < <(collect)
}

# Index (1-based) of the first selectable row at/after $1 walking in direction $2 (wraps)
step_sel() {
    local i=$1 dir=$2 n=${#rtext} t
    for (( t=0; t<n; t++ )); do
        (( i += dir )); (( i > n )) && i=1; (( i < 1 )) && i=n
        [[ ${rsel[i]} == 1 ]] && { print $i; return }
    done
    print 1
}

render() {
    build
    local cur=1 i
    for (( i=1; i<=${#rinfo}; i++ )); do [[ ${rinfo[i]} == "$ROFI_INFO" && ${rsel[i]} == 1 ]] && { cur=$i; break; }; done
    (( ROFI_RETV == 0 )) && cur=$(step_sel 0 1)
    [[ $NAV == up ]] && cur=$(step_sel $cur -1)
    [[ $NAV == down ]] && cur=$(step_sel $cur 1)
    print -n '\0prompt\x1fvolume\n\0markup-rows\x1ftrue\n\0no-custom\x1ftrue\n\0keep-selection\x1ftrue\n\0use-hot-keys\x1ftrue\n'
    printf '\0message\x1f%s\n\0new-selection\x1f%s\n' "$MSG" $(( cur - 1 ))
    for (( i=1; i<=${#rtext}; i++ )); do
        if [[ ${rsel[i]} == 1 ]]; then printf '%s\0info\x1f%s\n' "${rtext[i]}" "${rinfo[i]}"
        else printf '%s\0nonselectable\x1ftrue\x1finfo\x1f%s\n' "${rtext[i]}" "${rinfo[i]}"; fi
    done
}

if (( ROFI_RETV > 0 )); then
    k="${ROFI_INFO%%:*}"; id="${ROFI_INFO#*:}"
    NAV=; cyc=0
    case $ROFI_RETV in 10) d=-5;; 11) d=5;; 12) d=-1;; 13) d=1;; 14) d=0; mute=1;; 15) NAV=up; k=hdr;; 16) NAV=down; k=hdr;; 17) d=0; cyc=1;; 18) d=0; cyc=-1;; *) d=0; mute=0;; esac
    if [[ $k != hdr ]]; then
        if (( cyc != 0 )); then
            # Tab: send this app's stream to the next/previous available output
            if [[ $k == notif ]]; then
                outs=( auto ${(f)"$(collect | awk -F'\t' '$1=="sink"{print $2}')"} )
                curs=auto; [[ -f $sstate ]] && curs="$(<$sstate)"
                pos=${outs[(i)$curs]}; (( pos > ${#outs} )) && pos=1
                np=$(( (pos - 1 + cyc + ${#outs}) % ${#outs} + 1 )); tgt=${outs[np]}
                if [[ $tgt == raop_* ]]; then
                    an=""; at=0; [[ -f $armfile ]] && read -r an at <"$armfile"
                    if [[ $an == $tgt ]] && (( EPOCHSECONDS - at < 6 )); then rm -f "$armfile"; print -r -- "$tgt" >|"$sstate"
                    else print "$tgt $EPOCHSECONDS" >|"$armfile"; fi
                else
                    rm -f "$armfile"; print -r -- "$tgt" >|"$sstate"
                fi
            elif [[ $k == in ]]; then
                outs=( ${(f)"$(collect | awk -F'\t' '$1=="sink"{print $2}')"} )
                curs="$(collect | awk -F'\t' -v i=$id '$1=="in" && $2==i {print $9}')"
                pos=${outs[(i)$curs]}; (( pos > ${#outs} )) && pos=0
                np=$(( (pos - 1 + cyc + ${#outs}) % ${#outs} + 1 ))
                tgt=${outs[np]}
                if [[ $tgt == raop_* ]]; then
                    an=""; at=0; [[ -f $armfile ]] && read -r an at <"$armfile"
                    if [[ $an == $tgt ]] && (( EPOCHSECONDS - at < 6 )); then
                        rm -f "$armfile"; pactl move-sink-input $id "$tgt"
                    else
                        print "$tgt $EPOCHSECONDS" >|"$armfile"
                    fi
                else
                    rm -f "$armfile"; pactl move-sink-input $id "$tgt"
                fi
            fi
        elif (( d == 0 )); then
            if [[ $k == sink && $mute == 0 ]]; then
                # Enter on an output = make it the default (and move playing streams to it)
                an=""; at=0
                [[ $id == raop_* ]] && [[ -f $armfile ]] && read -r an at <"$armfile"
                if [[ $id == raop_* ]] && ! [[ $an == $id ]] || { [[ $id == raop_* ]] && (( EPOCHSECONDS - at >= 6 )) }; then
                    print "$id $EPOCHSECONDS" >|"$armfile"
                else
                    rm -f "$armfile"
                    pactl set-default-sink "$id"
                    pactl list short sink-inputs | cut -f1 | while read -r si; do pactl move-sink-input $si "$id" 2>/dev/null; done
                fi
            else
                case $k in
                    sink) pactl set-sink-mute "$id" toggle ;;
                    in)   pactl set-sink-input-mute $id toggle ;;
                esac
            fi
        else
            cur="$(collect | awk -F'\t' -v k=$k -v i=$id '$1==k && $2==i {print $5}')"
            if [[ -n $cur ]]; then
                new=$(clamp $(( cur + d )))
                case $k in
                    sink)  pactl set-sink-volume "$id" ${new}% ;;
                    in)    pactl set-sink-input-volume $id ${new}% ;;
                    notif) print $new >"$nstate"
                           paplay "${ndev[@]}" --volume=$(( 65536 * new / 100 )) "$sounds/volume.wav" >/dev/null 2>&1 &! ;;
                esac
            fi
        fi
    fi
fi
render
