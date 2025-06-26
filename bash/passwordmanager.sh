#!/usr/bin/env bash
################################################################################
# Script:   passwordmanager.sh                                                 #
# Function:                                                                    #
# Usage:    passwordmanager.sh [-h]                                            #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 04-14-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

_start() {
  for i in 1 2 3; do
    $secure decrypt ||
      {
        _print_error '%s\n\n' 'Decryption failed'
        return 1
      }
    if [ $? -eq 0 ]; then
      break
    elif [ $i -eq 3]; then
      _print_error '%s\n\n' 'Authentication failed'
      return 2
    fi
  done
}

_stop() {
  $secure encrypt ||
    {
      _print_error '%s\n\n' 'Encryption failed'
      exit 98
    }
}

_menu() {
  local usrin lastopt
  declare -a menuopts
  menuopts=("$@")
  _display_menu "${menuopts[@]}"
  lastopt=$((${#menuopts[@]}-1))
  read -t $wait_time -p "Enter Choice [1-$lastopt] " usrin
  case "$usrin" in
    [0-9]*)
      _${menuopts[$usrin],}
      ;;
    ""|[Qq]*)
      exit 0
      ;;
    *)
      _clear $debug
      printf '%s\n' "$usrin $NOT_RECOGNIZED_OPTION"
      ;;
  esac
}

_main_menu() {
  local prompt menu_items
  printf '%s\n' 'MAIN MENU'
  prompt='Select one of the following options'
  menu_items="Add Quit"
  if [ -f "$outfile" ]; then
    menu_items="List $menu_items"
  fi
  _menu "$prompt" $menu_items
  _main_menu
}

_list() {
  _clear $debug
  printf '%s\n' 'ACCOUNT LIST'
  mapfile -t listopts < <(awk -F ':' '{print $1}' $outfile)
  listopts=('Please choose one of the following accounts' "${listopts[@]}" \
    'Back to Main Menu')
  _display_menu "${listopts[@]}"
  local usrin lastopt=$((${#listopts[@]}-1))
  read -t $wait_time -p "Enter Choice [1-$lastopt] " usrin
  echo
  case "$usrin" in
    ""|$lastopt)
      _clear $debug
      _main_menu
      ;;
    [0-9]*)
      _select "${listopts[$usrin]}"
      ;;
    [Qq]*)
      exit 0
      ;;
    *)
      _clear $debug
      printf '%s\n' "$usrin $NOT_RECOGNIZED_OPTION"
      ;;
  esac
  _list
}

_add() {
  _clear $debug
  read -p 'Please enter the name of this account: ' accname
  if [ -f "$outfile" ] && grep -q "$accname" $outfile; then
    _clear $debug
    _print_error 'This name already exists.'
    return 81
  fi
  read -p 'Please enter the user name for this account: ' usrname
  printf '%s' 'Please specify the password length (press enter for default) : '
  read length
  printf '%s' 'Please specify the number of special characters for the password'
  read -p ' (press enter for default) : ' numspec
  printf '%s' "Please specify any special characters ($special_chars) that"
  read -p ' should not be used (press enter for default): ' excspec
  local args
  if [ -n "$length" ]; then
    args=" -l $length"
  fi
  if [ -n "$numspec" ]; then
    args="$args -n $numspec"
  fi
  if [ -n "$excspec" ]; then
    spchars=$(echo "$special_chars" | tr -d "$excspec")
    args="$args -s $spchars"
  fi
  str=$($random $args)
  rc=$?
  if [ $rc -ne 0 ]; then
    _clear $debug
    _print_error '%s\n\n' 'An error ocurred while generating a new password'
    return $rc
  fi
  echo "$accname:$length:$numspec:$espchars:$usrname/$str" >>$outfile
  accinfo=$(grep "^$accname" $outfile)
  _show
  _clear $debug
}

_quit() {
  exit 0
}

_select() {
  accname="${1:?}"
  _clear $debug
  _menu "Select one of the following actions for account $accname" 'Update' \
    'Delete' 'Show'
  _list
}

_update() {
  length=$(echo "$accinfo" | cut -d : -f 2)
  numspec=$(echo "$accinfo" | cut -d : -f 3)
  excspec=$(echo "$accinfo" | cut -d : -f 4)
  local args
  if [ -n "$length" ]; then
    args=" -l $length"
  fi
  if [ -n "$numspec" ]; then
    args="$args -n $numspec"
  fi
  if [ -n "$excspec" ]; then
    spchars=$(echo "$special_chars" | tr -d "$excspec")
    args="$args -s $spchars"
  fi
  str=$($random $args)
  rc=$?
  if [ $rc -ne 0 ]; then
    _clear $debug
    _print_error '%s\n\n' 'An error ocurred while generating a new password'
    return $rc
  fi
  sed -i "s/^\($accname.*:.*\/\).*/\1$str/" $outfile
  printf '%s\n' "$accname updated."
  _show
}

_delete() {
  _clear $debug
  local usrin
  if _yes_no_prompt "Are you sure that you want to delete $accname?"; then
    sed -i "/^$accname/d" $outfile
    printf '%s\n' "$accname deleted."
    read -t $wait_time -n 1 -p "$ANY_KEY_CONTINUE"
  fi
}

_show() {
  local creds username str
  accinfo=$(grep "^$accname" $outfile)
  creds=${accinfo##*:}
  usrname=$(echo "$creds" | cut -d / -f 1)
  str=$(echo "$creds" | cut -d / -f 2)
  _clear $debug
  echo "$str" | wl-copy
  printf '%s - %s\n' "${accname^^}" "$usrname"
  read -t $wait_time -n 1 -p "$ANY_KEY_CONTINUE"
  echo | wl-copy
}

####################
# passwordmanager.sh START
####################
help=$(cat <<END
Program description goes here.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message

END
)

if [ "$1" = '--debug' ]; then
  debug=$1
  shift
fi

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

secure="$(dirname $0)/secure.sh"
random="$(dirname $0)/printrandom.sh"
outfile="$HOME/Documents/secure/.passfile"
special_chars='@#$%&_+='
wait_time=300

trap _stop EXIT

_start || { _print_error '%s\n\n' 'Failed to start'; exit 99; }
_clear $debug
_main_menu

exit 0
