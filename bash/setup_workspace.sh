#!/usr/bin/env bash
################################################################################
# Script:   setup_workspace.sh                                                 #
# Function:                                                                    #
# Usage:    setup_workspace.sh [-h] [-t type]                                  #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-29-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [-t type]'

####################
# setup_workspace.sh START
####################
help=$(cat <<END
Program description goes here.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message
  -t TYPE       The type of workspace; the name of a subdirectory in ~/work

END
)

while getopts 'ht:' OPT; do
  case "$OPT" in
    h)
      printf '%s\n' "$help"
      exit 0
      ;;
    t)
      type="$OPTARG"
      ;;
    *)
      _usage
      ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 1 ]; then
  _invalid_arguments "$@"
fi

ws_dir="$HOME/work"
if [ -n "$type" ]; then
  ws_dir="$ws_dir/$type"
fi

[ -d "$ws_dir" ] ||
  if ! _yes_no_prompt "$ws_dir does not exist, do you want to create it?"; then
    exit 0
  fi

workspace="$ws_dir/$1"
mkdir -p "$workspace"

if [ "$type" = 'sh' ]; then
  git_dir="$HOME/git/shell_scripts/bash"
  ( cd "$git_dir" && git checkout dvlp && git pull; )
  cp "$git_dir/common.functions" "$workspace"
fi

echo "cd $workspace"

exit 0
