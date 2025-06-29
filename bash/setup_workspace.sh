#!/usr/bin/env bash
################################################################################
# Script:   setup_workspace.sh                                                 #
# Function:                                                                    #
# Usage:    setup_workspace.sh [-h]                                            #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-29-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

####################
# setup_workspace.sh START
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

if [ $# -ne 1 ]; then
  _invalid_arguments "$@"
fi

workspace="$1"
git_dir="$HOME/git/shell_scripts/bash"
bin_dir="$HOME/bin"
ws_dir="$HOME/work/sh"

( cd "$git_dir" && git checkout main && git pull; )

mkdir "$ws_dir/$workspace"

cp "$git_dir/common.functions" "$ws_dir/$workspace"

exit 0
