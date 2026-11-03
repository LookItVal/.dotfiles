ZIM_HOME=~/.config/zsh/zim
ZDOTDIR=~/.config/zsh/

# Lerd completions path (must be set before completion system is initialized)
fpath=($HOME/.local/share/zsh/site-functions $fpath)

# Stolen from Tyler, im not using this now
# Used by zsh-tab-title module
ZSH_TAB_TITLE_ADDITIONAL_TERMS='alacritty'
ZSH_TAB_TITLE_ONLY_FOLDER=true

# Install Zim if not currently installed
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]
then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]
then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

# Lerd completions (must be in fpath before Zim's completion module runs compinit)
fpath=(/home/val/.local/share/zsh/site-functions $fpath)

# File type colors in the catppuccin macchiato palette, for eza, fd (fzf's
# file lists) and tab completion. Set before zim, whose completion reads it.
export LS_COLORS="di=1;38;2;138;173;244:ln=38;2;139;213;202:ex=1;38;2;166;218;149:\
fi=38;2;202;211;245:or=38;2;237;135;150:mi=38;2;237;135;150:\
pi=38;2;238;212;159:so=38;2;245;189;230:bd=38;2;245;169;127:cd=38;2;245;169;127:\
su=38;2;36;39;58;48;2;237;135;150:sg=38;2;36;39;58;48;2;238;212;159:\
tw=38;2;36;39;58;48;2;166;218;149:ow=1;38;2;138;173;244"

# Initialize modules.
source ${ZIM_HOME}/init.zsh

# fzf look: catppuccin macchiato (no bg, terminals are transparent).
# Set after zim's fzf module, which adds its own previews to the *_OPTS.
# Each box has its own color: search mauve, results blue, preview teal.
# Matches mauve, pointer pink, marker green, counter peach, spinner yellow.
# ctrl-/ toggles the preview everywhere.
export FZF_DEFAULT_OPTS=" \
--color=fg:#CAD3F5,fg+:#CAD3F5,bg+:#443F60,selected-bg:#494D64 \
--color=hl:#C6A0F6:bold,hl+:#C6A0F6:bold,query:#CAD3F5:bold,ghost:#6E738D \
--color=prompt:#C6A0F6,pointer:#F5BDE6,marker:#A6DA95,spinner:#EED49F \
--color=info:#F5A97F,header:#91D7E3,separator:#494D64,scrollbar:#B7BDF8 \
--color=border:#6E738D,label:#CAD3F5 \
--color=input-border:#C6A0F6,input-label:#C6A0F6:bold \
--color=list-border:#8AADF4,list-label:#8AADF4:bold \
--color=preview-border:#8BD5CA,preview-label:#8BD5CA:bold \
--style full --layout reverse --height 60% --info inline-right \
--highlight-line --pointer '▌' --marker '┃' --prompt '❯ ' \
--scrollbar '│' --ghost 'type to search…'"

# History: the preview shows the full command, syntax highlighted (BAT_THEME).
_fzf_hist_preview='echo {2..}'
(( $+commands[bat] )) && _fzf_hist_preview+=' | bat --language=zsh --style=plain --color=always'
export FZF_CTRL_R_OPTS=" \
--input-label ' 󰋚 History ' --preview-label ' Command ' \
--preview '$_fzf_hist_preview' --preview-window 'down:3:wrap' \
--bind 'ctrl-/:toggle-preview'"
unset _fzf_hist_preview

export FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS \
--input-label '  Files ' --preview-label ' Preview '"
(( $+commands[eza] )) && export FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS \
--input-label '  Directories ' --preview-label ' Contents ' \
--preview 'eza --tree --level=2 --icons=auto --color=always {} | head -200'"

# Color the file and directory lists too (fd uses LS_COLORS, set above).
if [[ $FZF_ALT_C_COMMAND == *fd* ]]; then
  FZF_ALT_C_COMMAND+=' --color=always'
  FZF_ALT_C_OPTS+=' --ansi'
fi
if [[ $FZF_CTRL_T_COMMAND == *fd* ]]; then
  FZF_CTRL_T_COMMAND+=' --color=always'
  FZF_CTRL_T_OPTS+=' --ansi'
fi

# Aliases
# exa aliases
alias l='eza'
alias ls='l'
alias la='l -a'
alias lr='l --tree'
alias ll='ls --long --header'
alias lsr='ls --tree'
alias llr='ll --tree'
alias lsa='ls -a'
alias lla='ll -a'
alias lra='llr -a'

# nvim aliases
alias v='nvim'
alias vi='v'
alias vim='v'

export EDITOR=nvim
export VISUAL=nvim

# general aliases
alias pls='sudo $(fc -ln -1)'
alias fetch='fastfetch --config ~/.config/fastfetch/config.jsonc'
alias reboot-windows='sudo grub-reboot "Windows Boot Manager" && reboot'
(( $+commands[neoclear] )) && alias clear='neoclear --directions all'

# claude versions
alias claude-personal='CLAUDE_CONFIG_DIR="$HOME/.claude-personal" claude'

# get os
os=$(uname -s)
if [ $os = "Darwin" ]; then
  os="mac"
fi
if [ $os =  "Linux" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    os=$ID
  else
    os="unknown"
  fi
fi

# NixOS boots through systemd-boot, not GRUB
if [ $os = "nixos" ]; then
  alias reboot-windows='systemctl reboot --boot-loader-entry=auto-windows'
fi

# if os is ubuntu
if [ $os = "ubuntu" ]; then
  # UBUNTU path for snap
  export PATH=$PATH:/snap/bin
fi

# if os is not arch/nixos and tmux is installed
if [ $os != "arch" ] && [ $os != "nixos" ] && (( $+commands[tmux] )); then
  # Open or attach to tmux session
  if [ -z "$TMUX" ]; then
    tmux has-session 2>/dev/null
    if [ $? != 0 ]; then
      exec tmux
    else
      exec tmux attach-session
    fi
  fi
fi



# Added by Lerd installer
export PATH="$HOME/.local/bin:$PATH"

# Lerd
export PATH="$HOME/.local/share/lerd/bin:$PATH"

# Lerd
export PATH="/home/val/.local/share/lerd/bin:$PATH"

