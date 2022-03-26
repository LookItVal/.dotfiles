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
