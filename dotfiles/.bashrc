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

# show git branch
function parse_git_branch {
   git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# show git repo root dir
function git_repo_root {
    basename "$(git rev-parse --show-toplevel 2> /dev/null)"
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

export PATH="/usr/lib/ccache/:$PATH"
export PATH=$PATH:~/.local/bin
export PATH=$PATH:~/bin

alias mx='env TERM=xterm-256color emacs -Q -nw'
export EDITOR="mx"

alias tmux='tmux attach || tmux new'
alias socks5='ssh -D 1080 -f -C -q -N deploy@do-ubuntu-01 -p 443'

alias ll='ls -lAh'

cd() { builtin cd "$@" && ll; }
mcd() { mkdir "$1" && builtin cd "$1"; }

# A simple Bash script for printing timing information for each command line
# executed.
#
# For the most up-to-date version, as well as further information and
# installation instructions, please visit the GitHub project page at
#     https://github.com/jichuan89/bash-command-timer

# SETTINGS
# ========
#
# Whether to enable the command timer by default.
#
# To temporarily disable the printing of timing information, type the following
# in a session:
#     BCT_ENABLE=0
# To re-enable:
#     BCT_ENABLE=1
BCT_ENABLE=1

# The color of the output.
#
# This should be a color string  usable in a VT100 escape sequence (see
# http://en.wikipedia.org/wiki/ANSI_escape_code#Colors), without the
# escape sequence prefix and suffix. For example, bold red would be '1;31'.
#
# If empty, disable colored output. Set it to empty if your terminal does not
# support VT100 escape sequences.
BCT_COLOR='33'

# The display format of the current time.
#
# This is a strftime format string (see http://strftime.org/). To tweak the
# display format of the current time, change the following line to your desired
# pattern.
#
# If empty, disables printing of current time.
BCT_TIME_FORMAT='%b %d %H:%M:%S'

# Whether to print command timings up to millisecond precision.
#
# If set to 0, will print up to seconds precision.
BCT_MILLIS=1

# Wheter to wrap to the next line if the output string would overlap with
# characters of last command's output
BCT_WRAP=0


# IMPLEMENTATION
# ==============

# BCTTime:
#
# Command to print out the current time in nanoseconds. This is required
# because the "date" command in OS X and BSD do not support the %N sequence.
#
# BCTPrintTime:
#
# Command to print out a timestamp using BCT_TIME_FORMAT. The timestamp should
# be in seconds. This is required because the "date" command in Linux and OS X
# use different arguments to specify the timestamp to print.
if date +'%N' | grep -qv 'N'; then
  BCTTime="date '+%s%N'"
  function BCTPrintTime() {
    date --date="@$1" +"$BCT_TIME_FORMAT"
  }
elif hash gdate 2>/dev/null && gdate +'%N' | grep -qv 'N'; then
  BCTTime="gdate '+%s%N'"
  function BCTPrintTime() {
    gdate --date="@$1" +"$BCT_TIME_FORMAT"
  }
elif hash perl 2>/dev/null; then
  BCTTime="perl -MTime::HiRes -e 'printf(\"%d\",Time::HiRes::time()*1000000000)'"
  function BCTPrintTime() {
    date -r "$1" +"$BCT_TIME_FORMAT"
  }
else
  echo 'No compatible date, gdate or perl commands found, aborting'
  exit 1
fi

# The debug trap is invoked before the execution of each command typed by the
# user (once for every command in a composite command) and again before the
# execution of PROMPT_COMMAND after the user's command finishes. Thus, to be
# able to preserve the timestamp before the execution of the first command, we
# set the BCT_AT_PROMPT flag in PROMPT_COMMAND, only set the start time if the
# flag is set and clear it after the first execution.
BCT_AT_PROMPT=1
function BCTPreCommand() {
  if [ -z "$BCT_AT_PROMPT" ]; then
    return
  fi
  unset BCT_AT_PROMPT
  BCT_COMMAND_START_TIME=$(eval $BCTTime)
}
trap 'BCTPreCommand' DEBUG

# Bash will automatically set COLUMNS to the current terminal width.
export COLUMNS

# Flag to prevent printing out the time upon first login.
BCT_FIRST_PROMPT=1
# This is executed before printing out the prompt.
function BCTPostCommand() {
  BCT_AT_PROMPT=1

  if [ -n "$BCT_FIRST_PROMPT" ]; then
    unset BCT_FIRST_PROMPT
    return
  fi

  if [ -z "$BCT_ENABLE" ] || [ $BCT_ENABLE -ne 1 ]; then
    return
  fi

  # BCTTime prints out time in nanoseconds.
  local MSEC=1000000
  local SEC=$(($MSEC * 1000))
  local MIN=$((60 * $SEC))
  local HOUR=$((60 * $MIN))
  local DAY=$((24 * $HOUR))

  local command_start_time=$BCT_COMMAND_START_TIME
  local command_end_time=$(eval $BCTTime)
  local command_time=$(($command_end_time - $command_start_time))
  local num_days=$(($command_time / $DAY))
  local num_hours=$(($command_time % $DAY / $HOUR))
  local num_mins=$(($command_time % $HOUR / $MIN))
  local num_secs=$(($command_time % $MIN / $SEC))
  local num_msecs=$(($command_time % $SEC / $MSEC))
  local time_str=""
  if [ $num_days -gt 0 ]; then
    time_str="${time_str}${num_days}d "
  fi
  if [ $num_hours -gt 0 ]; then
    time_str="${time_str}${num_hours}h "
  fi
  if [ $num_mins -gt 0 ]; then
    time_str="${time_str}${num_mins}m "
  fi
  local num_msecs_pretty=''
  if [ -n "$BCT_MILLIS" ] && [ $BCT_MILLIS -eq 1 ]; then
    local num_msecs_pretty=$(printf '%03d' $num_msecs)
  fi
  time_str="${time_str}${num_secs}s${num_msecs_pretty}"
  now_str=$(BCTPrintTime $(($command_end_time / $SEC)))
  if [ -n "$now_str" ]; then
    local output_str="[ $time_str | $now_str ]"
  else
    local output_str="[ $time_str ]"
  fi
  if [ -n "$BCT_COLOR" ]; then
    local output_str_colored="\033[${BCT_COLOR}m${output_str}\033[0m"
  else
    local output_str_colored="${output_str}"
  fi
  # Trick to make sure the output wraps to the next line if there is not
  # enough room for the string (only when BCT_WRAP == 1)
  if [ -n "$BCT_WRAP" ] && [ $BCT_WRAP -eq 1 ]; then
    # we'll print as many spaces as characters exist in output_str, plus 2
    local wrap_space_prefix="${output_str//?/ }  "
  else
    local wrap_space_prefix=""
  fi

  # Move to the end of the line. This will NOT wrap to the next line
  # unless you have BCT_WRAP == 1
  echo -ne "$wrap_space_prefix\033[${COLUMNS}C"
  # Move back (length of output_str) columns.
  echo -ne "\033[${#output_str}D"
  # Finally, print output.
  echo -e "${output_str_colored}"
}
PROMPT_COMMAND='BCTPostCommand'
