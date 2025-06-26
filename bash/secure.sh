#!/usr/bin/env bash
################################################################################
# Script:   secure.sh                                                          #
# Function:                                                                    #
# Usage:    secure.sh [-h] mode                                                #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 04-06-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] mode'

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
help=$(cat <<END
Create a new bash script file from a template.

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

secure_dir="$HOME/.secure"
if [ ! -d "$secure_dir" ]; then
  mkdir $secure_dir && chmod 700 $secure_dir
fi
. $secure_dir/config

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
