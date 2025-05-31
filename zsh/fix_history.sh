#!/usr/bin/env zsh
################################################################################
# Script:   fix_history.sh                                                     #
# Function:                                                                    #
# Usage:    fix_history.sh [-h]                                                #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 05-31-2025                                                     #
#                                                                              #
################################################################################
USAGE_STR='[-h]'

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

mv ~/.zsh_history ~/.zsh_history_bad
strings ~/.zsh_history_bad > ~/.zsh_history
fc -R ~/.zsh_history
rm ~/.zsh_history_bad

exit 0
