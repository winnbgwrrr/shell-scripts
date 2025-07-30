#!/usr/bin/env bash
################################################################################
# Script:   visual_grep.sh                                                     #
# Function: An interactive way to grep files that provides a preview of the    #
#           sections of the file that contain a match.                         #
#                                                                              #
# Usage:    visual_grep.sh [-h] [-w] [-s] pattern file ...                     #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-02-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [-w] [-s] pattern file ...'

####################
# visual_grep.sh START
####################
help=$(cat <<END
An interactive way to grep files that provides a preview of the sections of the
file that contain a match.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message
  -s            Case sensitive pattern matching
  -w            Force PATTERN to match only whole words

END
)

g_opts='-i'
while getopts 'hsw' OPT; do
  case "$OPT" in
    h)
      printf '%s\n' "$help"
      exit 0
      ;;
    s)
      g_opts="${g_opts//i}"
      ;;
    w)
      g_opts="${g_opts}w"
      ;;
    *)
      _usage
      ;;
  esac
done

shift $((OPTIND-1))

if [ $# -eq 0 ]; then
  _invalid_arguments "$@"
fi

pattern="$1"
shift
path="$@"

if [ $(tput cols) -gt 187 ]; then
  layout='right'
  sep_width=$(($(tput cols)/2-7))
elif [ $(tput cols) -gt 156 ]; then
  layout='right,60%'
  sep_width=$(($(tput cols)*3/5-7))
else
  layout='up'
  sep_width=$(($(tput cols)-7))
fi

tput setaf '6'
grep ${g_opts}rl "$pattern" $path 2>/dev/null |
  fzf --style default --multi --height 100% --exit-0 \
  --bind 'ctrl-o:become(printf "%s\n" {+}),enter:become(vim -b {+})' \
  --preview "grep_preview.sh $g_opts '$pattern' {} $sep_width" \
  --preview-window $layout
tput sgr0

exit 0
