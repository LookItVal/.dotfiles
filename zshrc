ZIM_HOME=~/.config/zsh/zim
ZDOTDIR=~/.config/zsh/

# Stolen from Tyler, im not using this now
# Used by zsh-tab-title module
# ZSH_TAB_TITLE_ADDITIONAL_TERMS='alacritty'
# ZSH_TAB_TITLE_ONLY_FOLDER=true

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

# Initialize modules.
source ${ZIM_HOME}/init.zsh

# Content from old .zshrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Aliases
# exa aliases
alias l='exa'
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

# general aliases
alias pls='sudo $(fc -ln -1)'

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

# if os is ubuntu
if [ $os = "ubuntu" ]; then
  # UBUNTU path for snap
  export PATH=$PATH:/snap/bin
fi

# if os is not arch
if [ $os != "arch" ]; then
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
