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

alias pls='sudo $(fc -ln -1)'

# UBUNTU path for snap
export PATH=$PATH:/snap/bin
