export QT_QPA_PLATFORMTHEME="qt5ct"
export EDITOR='nvim'
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
# fix "xdg-open fork-bomb" export your preferred browser from here
export BROWSER=/usr/bin/palemoon
export SHELL='/bin/zsh'
. "$HOME/.cargo/env"

export FZF_DEFAULT_COMMAND='fd'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
