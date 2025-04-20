#!/usr/bin/env bash
################################################################################
# Script:   secure.sh                                                          #
# Function:                                                                    #
# Usage:    secure.sh [-h]                                                     #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 04-06-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] mode'

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

_encrypt() {
  if [ ! -d "$decrypted_dir/$name" ]; then
    _print_error '%s\n' "$decrypted_dir/$name does not exist"
    exit 99
  fi
  if tar -cvf $tar_file -C $decrypted_dir $name; then
    rm -fr $decrypted_dir/$name
  else
    exit $?
  fi
  if gpg -o $gpg_file -r "$user" -e $tar_file; then
    rm $tar_file
  else
    exit $?
  fi
}

_decrypt() {
  if [ ! -f "$gpg_file" ]; then
    _print_error "$gpg_file does not exist"
    exit 98
  fi
  if gpg -o $tar_file -d $gpg_file; then
    rm $gpg_file
  else
    exit $?
  fi
  if tar -xvf $tar_file -C $decrypted_dir; then
    rm $tar_file
  else
    exit $?
  fi
}

####################
# secure.sh START
####################

script=$(basename $0)
name='secure'
decrypted_dir="$HOME/Documents"
secure_dir="$HOME/.secure"
tar_file="$secure_dir/$(_get_random_string 8 'A-Za-z0-9').tar"
gpg_file="$secure_dir/$name.tar.gpg"
user="Robert A Winslow"

while getopts 'h' OPT; do
  case "$OPT" in
    h|*)
      _usage "$USAGE_STR"
      ;;
  esac
done

shift $((OPTIND-1))

if [ ! -d "$secure_dir" ]; then
  mkdir $secure_dir && chmod 700 $secure_dir
fi

if [ $# -ne 1 ]; then
   _invalid_arguments "$@"
elif [ "$1" = 'encrypt' ]; then
  _encrypt
elif [ "$1" = 'decrypt' ]; then
  _decrypt
else
  _print_error '%s: %s is not a valid mode. See %s -h for help.\n' $script \
    "'$1'" $script
fi

exit 0
