# -*- mode: sh -*-

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# append to the history file, don't overwrite it
shopt -s histappend

# eternal bash history
export HISTSIZE=
export HISTFILESIZE=

# ignore ls, ps
export HISTIGNORE="ls:ps:htop:history"

export HISTTIMEFORMAT="%d/%m/%y %T "
# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# force commands that you entered on more than one line to be adjusted
# to fit on only one with the cmdhist option
shopt -s cmdhist

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

function parse_git_branch {
   git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if [ "$color_prompt" = yes ]; then
    PS1="${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\W\[\033[00m\] \$? \$(parse_git_branch) \$ "
else
    PS1="${debian_chroot:+($debian_chroot)}\W \$? \$(parse_git_branch) \$ "
fi
unset color_prompt force_color_prompt

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

[ -z "$TMUX" ] && export TERM=xterm-256color

export PATH="$HOME/workspace/ya/depot_tools:$PATH"
export PATH="/usr/lib/ccache/:$PATH"
export PATH=$PATH:~/.local/bin

alias tmux='tmux attach || tmux new'
alias ll='ls -lAh'

cd() { builtin cd "$@" && ll; }
mcd() { mkdir "$1" && builtin cd "$1"; }
