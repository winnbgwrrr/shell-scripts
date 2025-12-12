#!/usr/bin/env bash
################################################################################
# Script:   setup_workspace.sh                                                 #
# Function:                                                                    #
# Usage:    setup_workspace.sh [-h] [--TYPE]                                   #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-29-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [--TYPE]'

_get_long_opts() {
  type="${1%%/*}"
  ws_dir="$HOME/work/${1}"
  if [ ! -d "$ws_dir" ]; then
    _yes_no_prompt "$ws_dir does not exist, would you like to create it?" &&
      mkdir "$ws_dir" || exit 99
  fi
}

####################
# setup_workspace.sh START
####################
help=$(cat <<END
Program description goes here.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message
  --TYPE        The type of workspace; the name of a subdirectory in ~/work

END
)

while getopts '-:h' OPT; do
  case "$OPT" in
    -)
      _get_long_opts "$OPTARG"
      ;;
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

ws_dir="${ws_dir:-$HOME/work}"

if [ $# -ne 1 ]; then
  _invalid_arguments "$@"
fi

workspace="$1"
mkdir "$ws_dir/$workspace"

if [ "$type" = 'sh' ]; then
  git_dir="$HOME/git/shell_scripts/bash"
  ( cd "$git_dir" && git checkout dvlp && git pull; )
  cp "$git_dir/common.functions" "$ws_dir/$workspace"
fi

echo "cd $ws_dir"

exit 0
