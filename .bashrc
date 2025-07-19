#
# ~/.bashrc
use_color=true

complete -cf sudo
shopt -s checkwinsize

shopt -s expand_aliases

# Enable history appending instead of overwriting.  #139609
shopt -s histappend

# texlive setup
export PATH="$HOME/.local/texlive/2024/bin/x86_64-linux:$PATH"

# navigation
alias ..='cd ..' 
alias ...='cd ../..'
alias .3='cd ../../..'

# file manipulation
alias cp="cp -i"                          # confirm before overwriting something
alias df='df -h'                          # human-readable sizes
alias vim="nvim"
alias vimdiff="nvim -d"


alias ll="ls -l"
alias la="ls -a"

# sane grep defaults
alias grep='grep -rni'
