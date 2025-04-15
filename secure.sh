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

USAGE_STR='[-h] [-d file] [-e user:directory]'

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
  local directory user
  directory=${1:?}
  user=${2:?}
  if [ ! -d "$directory" ]; then
    _print_error "No such directory $directory"
    exit 98
  fi
  tarfile=$(basename $directory).tar
  if tar -cvf $tarfile $directory; then
    rm -fr $directory
  else
    exit $?
  fi
  if gpg -e -r winsl $tarfile; then
    rm $tarfile
  else
    exit $?
  fi
}

_decrypt() {
  local tarfile
  tarfile=${1:?}
  if [ "${tarfile##*.}" = "gpg" ]; then
    tarfile=${tarfile%.*}
  elif [ "${tarfile##*.}" != "tar" ]; then
    tarfile=$tarfile.tar
  fi
  if [ ! -f "$tarfile.gpg" ]; then
    _print_error "No such file $tarfile.gpg"
    exit 97
  fi
  if gpg -o secure.tar -d $tarfile.gpg; then
    rm $tarfile.gpg
  else
    exit $?
  fi
  if tar -xvf $tarfile; then
    rm $tarfile
  else
    exit $?
  fi
}

_encrypt_decrypt() {
  _print_error 'The encrypt and decrypt options are mutually exclusive'
  exit 99
}

_decrypt_encrypt() {
  _encrypt_decrypt
}

####################
# secure.sh START
####################

while getopts 'd:e:h' OPT; do
  case "$OPT" in
    d)
      func="${func}_decrypt"
      target=$OPTARG
      ;;
    e)
      if echo "$OPTARG" | grep -q ':'; then
        func="${func}_encrypt"
        target=${OPTARG#*:}
        user=${OPTARG%:*}
      fi
      ;;
    h|*)
      _usage "$USAGE_STR"
      ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ] || [ -z "$func" ]; then
   _invalid_arguments "$@"
fi

$func $target $user

exit 0
