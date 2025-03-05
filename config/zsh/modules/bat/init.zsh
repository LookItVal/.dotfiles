# See [bat](https://github.com/sharkdp/bat):
# Sets bat as default for both cat and less, as well as sets my theme.

# Ensure bat is available
if (( ! ${+commands[bat]} )); then
  return 1
fi

export BAT_THEME="Solarized (light)"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"
alias cat='bat'
alias less='bat'