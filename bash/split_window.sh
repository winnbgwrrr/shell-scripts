#!/usr/bin/env bash
################################################################################
# Script:   split_window.sh                                                    #
# Function: Split the current window (or pane) into two panes. The split will  #
#           be horizontal or vertical depending on the ratio of the terminal   #
#           window.                                                            #
# Usage:    split_window.sh [-h] [-b] [-p percentage] [command]                #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-27-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [-b] [-p percentage] [command]'

####################
# split_window.sh START
####################
help=$(cat <<END
Split the current window (or pane) into two panes. The split will be horizontal
or vertical depending on the ratio of the terminal window.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message
  -b            The new pane will be created above or to the left of the old
                pane
  -p PERCENTAGE The percentage of the space that will be allocated to the new
                pane

END
)

while getopts 'hbp:' OPT; do
  case "$OPT" in
    h)
      printf '%s\n' "$help"
      exit 0
      ;;
    b)
      opts="b${opts}"
      ;;
    p)
      opts="${opts}p $OPTARG"
      ;;
    *)
      _usage
      ;;
  esac
done

shift $((OPTIND-1))

[ -z "$TMUX" ] && exit 0
[ $(($(tput cols)*10/$(tput lines))) -gt 36 ] &&
  tmux split-window -h$opts || tmux split-window -v$opts
tmux set-hook -p pane-focus-out "kill-pane"
[ $# -gt 0 ] && tmux send-keys "nocorrect $*" C-m

exit 0
