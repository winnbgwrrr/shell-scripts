#!/usr/bin/env bash
################################################################################
# Script:   explore.sh                                                         #
# Function: Explore a directory using a fuzzy file finder.                     #
# Usage:    explore.sh [-h] [directory]                                        #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 05-11-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [directory]'

########################################
# Display a menu of options for where to start fzf from if any of the specified
# locations exist in the current direcotry.
# Arguments:
#   None
# Outputs:
#   The menu
#   A message to stderr if the user does not provide a recognized option at
#   the menu prompt
# Returns:
#   0 if the user selects the 'Quit' option
########################################
_main_menu() {
  local lastopt usrin
  _display_menu "${optslist[@]}"
  lastopt=$((${#optslist[@]}-1))
  read -p "Enter Choice [1-$lastopt] " usrin
  clear
  case "$usrin" in
    $lastopt|[Qq]*)
      return 0
      ;;
  esac
  if ! _int_test "$usrin" || [ -z "${optslist[$usrin]}" ]; then
    _print_error '%s\n\n' "$usrin $NOT_RECOGNIZED_OPTION"
  else
    pushd  "${locations[${optslist[$usrin]}]}" >/dev/null
    _finder
    popd >/dev/null
  fi
  _main_menu
}

########################################
# Fuzzy find a file or directory. Selected files will open using an appropriate
# program, and selected directories will be navigated to.
# Arguments:
#   None
# Outputs:
#   The fzf user interface
# Returns:
#   0 if the user quits fzf without making a selection
########################################
_finder() {
  local file regex
  if [ "$PWD" = '/' ]; then
    regex='\(tmp\|dev\|proc\|home\)\|'
  fi
  file=$(find * -maxdepth 3 -regex "$regex.*.git" -prune \
    -o -not -readable -prune -o \( -type d -not -executable \) -prune \
    -o -exec file -00 --mime-encoding {} + 2>/dev/null | _file_filter | fzf \
    --bind "enter:transform:[ -d "{}" ] && echo 'accept' ||
      echo 'execute($open_file)+end-of-line+unix-line-discard'" \
    --bind 'alt-enter:become(echo alt:{})') || return 0
  if [ "${file:0:4}" = 'alt:' ]; then
    realpath "${file:4}"
    exit 0
  elif [ -d "$file" ]; then
    pushd "$file" >/dev/null
    _finder
    popd >/dev/null
  fi
}

########################################
# Filter a list of files to remove files that are not human readable.
# Arguments:
#   A null delimited list of files and file metadata
# Outputs:
#   A newline delimited list of files
########################################
_file_filter() {
  while read -r -d $'\0' file;
    do read -r -d $'\0' type;
    if [ -d "$file" ]; then
      echo "$file"
      continue
    elif [ "$type" != 'binary' ]; then
      echo "$file"
      continue
    fi
    case "$file" in
      *.gz|*.zip)
        echo "$file"
        ;;
    esac
  done;
}

####################
# explore.sh START
####################
help=$(cat <<END
Explore a directory using a fuzzy file finder.

Usage: $(basename $0) $USAGE_STR

  -h               Print this help message
  -m, --main-menu  Run in menu mode

END
)

while getopts 'hm' OPT; do
  case "$OPT" in
    h)
      printf '%s\n' "$help"
      exit 0
      ;;
    m)
      mode='menu'
      ;;
    *)
      _usage
      ;;
  esac
done

shift $((OPTIND-1))

open_file='
  file={}
  case "$file" in
    *.md|*.sh)
      vim -b "$file"
      ;;
    *.json)
      jq "." "$file" | less -S
      ;;
    *.log|*.config|*.conf|*.zip|*.gz)
      less -S "$file"
      ;;
    *)
      less -RS "$file"
      ;;
  esac
'

if [ "$1" = '--main-menu' ]; then
  mode='menu'
elif [ -d "$1" ]; then
  cd "$1" || exit 99
elif [ $# -gt 1 ]; then
  _invalid_arguments "$@"
fi

unset PS1
clear
if [ "$mode" = 'menu' ]; then
  declare -A locations
  declare -a optslist
  optslist=('Select one of the following categories:')
  locations[config]="$HOME/.config"
  locations[bash_scripts]="$HOME/git/shell_scripts/bash"
  locations[dotfiles]="$HOME/git/dotfiles"
  locations[home]="$HOME"
  locations[root]='/'
  locations[usr-bin]='/usr/bin'
  locations[usr-share]='/usr/share'
  locations[etc]='/etc'
  optslist+=("${!locations[@]}")
  optslist+=('Quit')
  _main_menu
else
  _finder
fi

exit 0
