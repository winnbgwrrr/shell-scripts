#!/usr/bin/env bash
################################################################################
# Script:   search.sh                                                          #
# Function:                                                                    #
# Usage:    search.sh [-h]                                                     #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 05-11-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

_search() {
  local message usrin lastopt
  declare -A locations
  declare -a optslist
  locations[hypr-config]="$HOME/.config/hypr/config"
  locations[bash_scripts]="$HOME/git/bash"
  locations[config_files]="$HOME/git/config_files"
  locations[home]="$HOME"
  locations[root]='/'
  locations[usr-bin]='/usr/bin'
  locations[usr-share]='/usr/share'
  locations[etc]='/etc'
  optslist=('Select one of the following locations:')
  for o in ${!locations[@]}; do
    if [ -d "${locations[$o]}" ]; then
      optslist+=("$o")
    else
      unset locations[$o]
    fi
  done
  optslist+=('Quit')
  clear
  [ -n "$message" ] && printf '%s\n\n' "$message"
  _display_menu "${optslist[@]}"
  lastopt=$((${#optslist[@]}-1))
  read -p "Enter Choice [1-$lastopt] " usrin
  case "$usrin" in
    $lastopt|[Qq]*)
      return 0
      ;;
    *)
      if ! _int_test "$usrin" || [ -z "${optslist[$usrin]}" ]; then
        _print_error '%s\n' "$usrin $NOT_RECOGNIZED_OPTION"
      else
        _fuzzy_find_file "${locations[${optslist[$usrin]}]}" || return 1
      fi
      ;;
  esac
  _search
}

_fuzzy_find_file() {
  local dir path cmd
  dir="${1:?}"
  cd $dir
  path=$dir/$(find * -maxdepth 3 -not -path '*/.?*/*' | fzf) || return 1
  cd -
  if [ -d "$path" ]; then
    _fuzzy_find_file "$path"
    return $?
  elif file $(realpath $path) | grep -qv 'text'; then
    printf '%s\n' "$path is not a text file"
    return 0
  fi
  case "$path" in
    *.sh)
      echo "vim -b $path"
      ;;
    *.json)
      echo "jq '.' | less -S $path"
      ;;
    *)
      echo "less -S $path"
      ;;
  esac | xargs tmux respawn-pane -kt search.1
}

_explore() {
  local usrin lastopt
  declare -A search_categories
  declare -a optslist
  optslist=('Select one of the following categories:')
  for o in "${!search_categories[@]}"; do
    if [ -d "${search_categories[$o]}" ] &&
      [ -n "$(ls -A ${search_categories[$o]})" ]
      then
      optslist+=("$o")
    else
      unset search_categories["$o"]
    fi
  done
  if [ ${#search_categories[@]} -eq 0 ]; then
    _find_and_display_file && return 0 || return 1
  fi
  optslist+=('Current Working Directory')
  optslist+=('Quit')
  clear
  _display_menu "${optslist[@]}"
  lastopt=$((${#optslist[@]}-1))
  read -p "Enter Choice [1-$lastopt] " usrin
  case "$usrin" in
    $lastopt|[Qq]*)
      return 0
      ;;
    $(($lastopt-1)))
      _find_and_display_file && { _explore; return 0; } || return 1
      ;;
    *)
      if ! _int_test "$usrin" || [ -z "${optslist[$usrin]}" ]; then
        _print_error "$usrin $NOT_RECOGNIZED_OPTION" || return 2
      else
        pushd "${search_categories[${optslist[$usrin]}]}"
        _find_and_display_file || return 1
        popd
      fi
      ;;
  esac
  _explore
}

_find_and_display_file() {
  local path
  path=$(find * -maxdepth 4 -not -path '*/.?*/*' | fzf) || return 0
  if [ -d "$path" ]; then
    pushd "$path" >/dev/null
    _find_and_display_file
    popd >/dev/null
  else
    _open_file "$path"
    _find_and_display_file
  fi
}

_open_file() {
  local file
  file="${1:?}"
  case "$file" in
    *.log)
      if grep -q 'The SAS System' $file; then
        less -S -p ^ERROR: $file
      else
        less -S $file
      fi
      ;;
    *.sas|*.sh)
      vim -b $file
      ;;
    *.json)
      jq '.' $file | less -S
      ;;
    *.zip|*.gz)
      less -S $file
      ;;
    *)
      if file $(realpath $file) | grep -q 'text'; then
        less -RS $file
      else
        _print_error "$(realpath $file) is not a text file"
        return 1
      fi
      ;;
  esac
}

####################
# START
####################
[ "${BASH_SOURCE[0]}" -ef "$0" ] || return 0

while getopts 'h' OPT; do
  case "$OPT" in
    h) _help ;;
    *) _usage ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
  _invalid_arguments "$@"
fi

tmux new-window -n search
tmux split-window -bh -p 30 \
  'bash -c "source search.sh; _search; tmux kill-window"'

exit 0
