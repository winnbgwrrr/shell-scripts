#!/usr/bin/env bash
################################################################################
# Script:   printrandom.sh                                                     #
# Function:                                                                    #
# Usage:    printrandom.sh [-h]                                                #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 04-14-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [-l length] [-n num_special_chars] [-s special_chars]'

########################################
# Prints this script's help message.
# Globals:
#   DOC_PAGE
# Arguments:
#   None
# Outputs:
#   The help message
########################################
_help() {
  printf 'Usage: %s\n' "$(basename $0) $USAGE_STR"
  printf '%s\n\n' 'Program description goes here.'
  printf '  %-16s%s\n' '-h' 'Print this help message'
  exit 0
}

_set_parameters() {
  length=${1-16}
  num_special=${2-1}
  echo "debug length $length num_special $num_special"
  if ! _int_test $length; then
    _print_error '%s\n\n' "length is not a valid integer"
    exit 99
  elif ! _int_test $num_special; then
    _print_error '%s\n\n' "num_special is not a valid integer"
    exit 98
  else
    if [ $length -ge $num_special ]; then
      length=$(($length - $num_special))
    else
      _print_error '%s\n\n' \
        'The number of special characters cannot exceed the length'
      exit 97
    fi
  fi
}

####################
# printrandom.sh START
####################
special_chars='@#$%&_+='

while getopts 'hl:n:s:' OPT; do
  case "$OPT" in
    h) _help ;;
    l) length=$OPTARG ;;
    n) num_special=$OPTARG ;;
    s) special_chars="$OPTARG" ;;
    *) _usage "$USAGE_STR" ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
  _invalid_arguments "$@"
fi

_set_parameters $length $num_special

{
   </dev/urandom LC_ALL=C grep -ao '[A-Za-z0-9]' | head -n $length
   for i in $(seq $num_special); do
      echo ${special_chars:$((RANDOM % ${#special_chars})):1}
   done
} | shuf | tr -d '\n'

exit 0
