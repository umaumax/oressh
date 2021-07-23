#!/usr/bin/env bash

# NOTE: for remote ssh
if [[ -r /etc/profile ]]; then
  source /etc/profile
fi
if [[ -r ~/.bash_profile ]]; then
  source ~/.bash_profile
elif [[ -r ~/.bash_login ]]; then
  source ~/.bash_login
elif [[ -r ~/.profile ]]; then
  source ~/.profile
fi

# NOTE: oressh use --rcfile option (which does not execute as login shell)
! shopt login_shell >/dev/null 2>&1 && [[ -f ~/.bashrc ]] && source ~/.bashrc

shopt | grep -q autocd && shopt -s autocd
shopt | grep -q dotglob && shopt -s dotglob

PS1='\[\e[1;33m\]\u@\h \w\n\[\e[1;36m\]\$\[\e[m\] '

# ignoredups,ignorespace
export HISTCONTROL=ignoreboth

# NOTE: change stop=^S keymap to stop=<undef>
stty stop undef

function cmdcheck() { type "$1" >/dev/null 2>&1; }
if cmdcheck vim; then
  alias vi='vim'
else
  alias vim='vi'
fi

! cmdcheck tree && function tree() {
  pwd
  find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/|  /g'
}

alias fix-terminal='stty sane; resize; reset'

alias grep='grep --color=auto'

alias h='history'
alias cl='clear'

if [[ $(uname) == "Darwin" ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi
alias l='ls'
alias ll='lsal'
alias lsal='ls -al'
alias lsalt='ls -alt'
alias lsaltr='ls -altr'

alias type='type -a'

alias qq='exit'
alias qqq='exit'
alias qqqq='exit'

# [umaumax/bifzf]( https://github.com/umaumax/bifzf )
! type >/dev/null 2>&1 fzf && function fzf() {
  (
    MAX_LINE=${BIFZF_MAX_LINE:-10}

    text=""
    cursor_pos=0
    target_number=0

    in_tty='/dev/tty'
    out_tty='/dev/tty'

    bifzf_help() {
      printf "\e[33m" 1>&2
      cat 1>&2 <<EOF
usage: $0
e.g.
ls | $0
EOF
      printf "\e[00m" 1>&2
    }

    if [[ ! -p /dev/stdin ]]; then
      bifzf_help
      exit 1
    fi
    lines=$(cat)

    bifzf_trap_handler() {
      local signal=$(($? - 128))
      bifzf_clear_display
      stty sane
      exit $signal
    }
    trap bifzf_trap_handler 1 2 3 15

    # get space
    {
      printf " %${MAX_LINE}s" | tr ' ' '\n'
      printf "\e[1A\e[${MAX_LINE}A" # tput cuu 10

      # save cursor position
      printf "\e7" # tput sc
    } >$out_tty

    bifzf_clear_display() {
      {
        # restore cursor position
        printf "\e8"  # tput rc
        # clear screen from cursor to end
        printf "\e[J" # tput cd
      } >$out_tty
    }
    bifzf_display() {
      local text="$1"
      local cursor_pos="$2"
      local target_number="$3"
      {
        # hide cursor
        printf "\e[\x3f\x32\x35\x6c" # tput civis
        bifzf_clear_display
        printf "\e[36m" 1>&2
        printf "> %s\n" "${text:0:$cursor_pos}${text:$cursor_pos}"
        printf "\e[00m" 1>&2
        printf "%s" "$lines" | grep --color=always -n "$text" | awk 'NR <='"$MAX_LINE"' { if (NR=='"$target_number"'+1) { printf "* "; } else { printf "  ";} printf "%s\n", $0}'
        # restore cursor position
        printf "\e8" # tput rc
        # move right
        printf "\e[2C"
        if [[ $cursor_pos != 0 ]]; then
          printf "\e[${cursor_pos}C" # tput cuf "$cursor_pos"
        fi
        # show cursor
        printf "\e[34h\e[?25h" # tput cnorm
      } >$out_tty
    }

    bifzf_main() {
      bifzf_display "$text" "$cursor_pos" "$target_number"
      while true; do
        IFS="" read -rsn1 input <$in_tty

        # enter
        if [[ -z "$input" ]]; then
          break
        fi
        # ESC
        if [[ "$input" == $'\x1b' ]]; then
          # pre_input="$input"
          IFS="" read -rsn1 input2 <$in_tty
          IFS="" read -rsn1 input3 <$in_tty
          input="${input}${input2}${input3}"

          # up
          if [[ "$input" == $'\x1b\x5b\x41' ]]; then
            ((target_number--))
            if [[ $target_number -lt 0 ]]; then
              target_number=0
            fi
          fi
          # down
          if [[ "$input" == $'\x1b\x5b\x42' ]]; then
            ((target_number++))
          fi
          # left
          if [[ "$input" == $'\x1b\x5b\x44' ]]; then
            ((cursor_pos--))
            if [[ $cursor_pos -lt 0 ]]; then
              cursor_pos=0
            fi
          fi
          # right
          if [[ "$input" == $'\x1b\x5b\x43' ]]; then
            ((cursor_pos++))
            if [[ $cursor_pos -gt ${#text} ]]; then
              cursor_pos=${#text}
            fi
          fi
          bifzf_display "$text" "$cursor_pos" "$target_number"
          continue
        fi
        target_number=0

        # delete
        if [[ "$input" == $'\x7f' ]]; then
          # text=${text%?}
          left_text="${text:0:$cursor_pos}"
          right_text="${text:$cursor_pos}"
          text="${left_text%?}${right_text}"
          # move left
          ((cursor_pos--))
          if [[ $cursor_pos -lt 0 ]]; then
            cursor_pos=0
          fi
        else
          text="${text}${input}"

          # move right
          ((cursor_pos++))
          if [[ $cursor_pos -gt ${#text} ]]; then
            cursor_pos=${#text}
          fi
        fi

        bifzf_display "$text" "$cursor_pos" "$target_number"
      done

      bifzf_clear_display
      output=$(printf "%s" "$lines" | grep "$text" | awk 'NR=='"$target_number"'+1 { printf "%s", $0}')
      printf "%s" "$output"
    }

    bifzf_main "$@"
  )
}

if type >/dev/null 2>&1 docker; then
  docker-exec() {
    local container_id=$(docker ps | fzf | awk '{print $1}')
    [[ -z $container_id ]] && return
    docker exec -it $container_id /bin/bash
  }
fi
