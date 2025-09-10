# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [ -z "$TMUX" ]; then
  if [[ -z "$OPEN_COPIED_TERM" ]]; then
    exec tmux
  else
    exec ~/scripts/open-helper-terminal.sh
  fi
else 
  ~/scripts/clean-tmux.sh
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# My stuff
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search
#

# Aliases
alias e='emacsclient -nca ""'
alias gadd="git add ."
alias ginit="git init ."
alias gs="git status"
alias v="nvim"
alias ts="tmux source ~/.config/tmux/tmux.conf"
alias tk="tmux kill-server"
alias zs="source ~/.zshrc"
alias n="nvim"
alias vim="NVIM_APPNAME=nvim-minimal nvim"
alias ss="satty --copy-command wl-copy --early-exit"
alias smpv="swayhide mpv"

alias nin="nvim"
export SUDO_EDITOR="/usr/bin/nvim"

alias ls="exa"
alias s="cd ~/.config/sway && nvim ."
alias key="setxkbmap gb -variant colemak_dh -option ctrl:swapcaps"

alias mp="swayhide mpv"

new() {
    echo -n "cd " > ~/.pd && pwd >> ~/.pd && kitty --detach --session ~/.pd
}

z() {
    if [[ $XDG_SESSION_TYPE == "wayland" ]]
    then
	swayhide zathura "$(fd -e pdf | fzf --scheme path)" && exit    
    else
	gobble zathura "$(fd -e pdf | fzf --scheme path)" && exit
    fi
}

nh() {
    $EDITOR $(fd --type file --hidden --regex "^\." | fzf --preview='bat --color always {}' --preview-window up)
}

browse() {
   cpath=$1
   until [[ -f $cpath ]]; do
       cpath=$({ fd . "$cpath"}| fzf --preview='bat --color always {} 2> /dev/null || tree -C' --preview-window up)
   done
   echo "$cpath"
}

projects() {
    { ls -d ~/repos/*(/); ls -d ~/.config/*(/); ls -d ~/.config/*(@); ls -d ~/Documents/*/*(/) ; cat ~/.projects }
}

p() {
    cd $(projects | fzf --preview='tree -C -L 2 --gitignore {}' --preview-window up)
    ls
}

mdh() {
    mv $(ls ~/Downloads/*(.) | fzf) ./
}

update() {
    print -P "Print %F{green}pacman -Syu $@%f"
	sudo pacman -Syu $1
}

function vi-yank-copy {
    zle vi-yank
    echo "$CUTBUFFER" | wl-copy
}

zle -N vi-yank-xclip
bindkey -M vicmd 'y' vi-yank-xclip
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto      # update automatically without asking
ENABLE_CORRECTION="true"

plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)
source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Vim Config
ZVM_VI_ESCAPE_BINDKEY="^S"
ZVM_VI_INSERT_ESCAPE_BINDKEY="^S"
bindkey -M vicmd -s 'L' '$'
bindkey -M vicmd -s 'H' '^'

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# start tmux on startup, must be done last
# if [[ "$TERM" != "screen" ]]; then
#   ~/scripts/open-helper-terminal.sh 
# else 
#   ~/scripts/clean-tmux.sh
# fi

