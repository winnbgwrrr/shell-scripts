#!/usr/bin/env bash
################################################################################
# Script:                                                                      #
# Function:                                                                    #
# Usage:                                                                  #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written:                                                      #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'
DOC_PAGE="$CONFLUENCE/TOOL/$(basename $0)"

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
  printf '\n  %s\n\n' "$DOC_PAGE"
  exit 0
}

####################
# START
####################

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

exit 0
