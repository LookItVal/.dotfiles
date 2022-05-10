# This is assuming you already have both Ripgrep, FD and Tmux already Installed

export FZF_TMUX=0
export FZF_TMUX_OPTS="-d 40%"
export FZF_DEFAULT_COMMAND="command fd -c always -H --no-ignore-vcs -E .git -tf" 
export FZF_CTRL_T_COMMAND="command rg -uu -g '!.git' --files"
export FZF_ALT_C_COMMAND="command fd -c never -H --no-ignore-vcs -E .git -td"
export FZF_DEFAULT_OPTS="--color=light"
