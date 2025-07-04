#!/usr/bin/env bash
################################################################################
# Script:   split_window.sh                                                    #
# Function:                                                                    #
# Usage:    split_window.sh [-h]                                               #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 07-04-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

####################
# split_window.sh START
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

[ -z "$TMUX" ] && exit 0
[ $(($(tput cols)*10/$(tput lines))) -gt 36 ] &&
  tmux split-window -h || tmux split-window -v
tmux set-hook -p pane-focus-out "kill-pane"
[ $# -gt 0 ] && tmux send-keys "$*" C-m

exit 0
