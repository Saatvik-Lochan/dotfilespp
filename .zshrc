# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# My stuff
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

# Aliases
alias e='emacsclient -nca ""'
alias gadd="git add ."
alias ginit="git init ."
alias gs="git status"
alias v="nvim"
alias ts="tmux source ~/.config/tmux/tmux.conf"
alias tk="tmux kill-server"

alias s="cd ~/.config/sway && nvim ."

alias key="setxkbmap gb -variant colemak_dh -option ctrl:swapcaps"

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

n() {
    $EDITOR $(browse .)
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

gc() {
    git commit -m $1
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

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto      # update automatically without asking

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# CTRL-/ to toggle small preview window to see the full command
# CTRL-Y to copy the command into clipboard using pbcopy

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval $(thefuck --alias)

# Vim Config
ZVM_VI_ESCAPE_BINDKEY="^S"
ZVM_VI_INSERT_ESCAPE_BINDKEY="^S"
bindkey -M vicmd -s 'L' '$'
bindkey -M vicmd -s 'H' '^'

# opam configuration
[[ ! -r /home/saatvikl/.opam/opam-init/init.zsh ]] || source /home/saatvikl/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# # start tmux on startup
[[ -z "$TMUX"  ]] && { exec tmux new -A -s "MAIN" }
