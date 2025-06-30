#!/usr/bin/env bash
################################################################################
# Script:   explore.sh                                                         #
# Function:                                                                    #
# Usage:    explore.sh [-h]                                                    #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 05-11-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

_main_menu() {
  local usrin lastopt error
  declare -A locations
  declare -a optslist
  optslist=('Select one of the following categories:')
  locations[config]="$HOME/.config"
  locations[bash_scripts]="$HOME/git/shell_scripts/bash"
  locations[config_files]="$HOME/git/dotfiles"
  locations[home]="$HOME"
  locations[root]='/'
  locations[usr-bin]='/usr/bin'
  locations[usr-share]='/usr/share'
  locations[etc]='/etc'
  for k in "${!locations[@]}"; do
    if [ -d "${locations[$k]}" ]; then
      optslist+=("$k")
    else
      unset locations["$k"]
    fi
  done
  optslist+=('Working Directory')
  optslist+=('Quit')
  _display_menu "${optslist[@]}"
  lastopt=$((${#optslist[@]}-1))
  read -p "Enter Choice [1-$lastopt] " usrin
  clear
  case "$usrin" in
    $lastopt|[Qq]*)
      return 0
      ;;
    $(($lastopt-1)))
      _finder
      ;;
    *)
      if ! _int_test "$usrin" || [ -z "${optslist[$usrin]}" ]; then
        _print_error '%s\n\n' "$usrin $NOT_RECOGNIZED_OPTION"
      else
        ( cd "${locations[${optslist[$usrin]}]}";  _finder; )
      fi
      ;;
  esac
  _main_menu
}

_finder() {
  local path
  path=$(find * -maxdepth 3 -not -path '*.git/*' 2>/dev/null | fzf) || return 0
  if [ -d "$path" ]; then
    pushd "$path" >/dev/null
    _finder
    popd >/dev/null
  else
    _open_file "$path" || return 1
    _finder
  fi
}

_open_file() {
  local file
  file="${1:?}"
  case "$file" in
    *.md|*.config|*.conf|*.sh)
      vim -b $file
      ;;
    *.json)
      jq "." $file | less -S
      ;;
    *.log|*.zip|*.gz)
      less $file
      ;;
    *)
      if [ "$(file "$file" --mime-encoding | cut -d ' ' -f 2)" = 'binary' ]; then
        _print_error '%s is a binary file\n\n' "$file"
        return 1
      else
        less -RS $file
      fi
      ;;
  esac
}

####################
# explore.sh START
####################
help=$(cat <<END
Program description goes here.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message

END
)

while getopts 'h' OPT; do
  case "$OPT" in
    h)
      printf '%s\n' "$help"
      exit 0
      ;;
    *)
      _usage
      ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
  _invalid_arguments "$@"
fi

clear
_main_menu

exit 0
