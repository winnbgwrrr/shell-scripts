#!/usr/bin/env bash
################################################################################
# Script:   visual_grep.sh                                                     #
# Function: An interactive way to grep files that provides a preview of the    #
#           sections of the file that contain a match.                         #
#                                                                              #
# Usage:    visual_grep.sh [-h] [-w] [-s] pattern file                         #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-02-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [-w] [-s] pattern file'
DOC_PAGE="$CONFLUENCE/TOOL/$(basename $0)"

########################################
# Print sections of a file where a specific pattern was found. The pattern
# itself will print with the default color that grep uses for highlighting. If
# multiple sections are printed a colorized separator will print between the
# sections.
# Arguments:
#   Options that need to be used with grep
#   The pattern that grep will use
#   The name of the file
# Outputs:
#   One or more sections of a file with the pattern highlighted and separator
#   between sections
########################################
_generate_preview() {
  local g_opts pattern file_name snip_size bln eln
  g_opts="$1"
  pattern="${2:?}"
  file_name="${3:?}"
  snip_size=7
  mapfile -t line_nums < <(grep -${g_opts}n "$pattern" $file_name |
    cut -d ':' -f 1)
  line_nums+=(0)
  for ln in ${line_nums[@]}; do
    if [ -z "$bln" ]; then
      if [ $ln -gt $snip_size ]; then
        bln=$(($ln-$snip_size))
      else
        bln=1
      fi
      eln=$(($ln+$snip_size))
    elif [ $ln -eq 0 ]; then
      sed -n "$bln,${eln}p" $file_name |
        grep --color=always -${g_opts}E "$pattern|$"
    elif [ $ln -lt $(($eln+$snip_size)) ]; then
      eln=$(($ln+$snip_size))
    else
      sed -n "$bln,${eln}p" $file_name |
        grep --color=always -${g_opts}E "$pattern|$"
      tput setaf 67
      echo; for i in {1..80}; do printf '%c' '~'; done; echo; echo
      tput sgr0
      bln=$(($ln-$snip_size))
      eln=$(($ln+$snip_size))
    fi
  done
}

########################################
# Print each argument on a separate line in color.
# Arguments:
#   A list of strings
# Outputs:
#   Each string on a separate line in color
########################################
_print_selected() {
  tput setaf '6'
  printf '%s\n' "$@"
  tput sgr0
}

export -f _generate_preview
export -f _print_selected

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

For additional information please reference:

  $DOC_PAGE
END
)

g_opts='i'
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

grep -${g_opts}rl "$pattern" $path 2>/dev/null |
  fzf --style default --multi --height 100% \
  --bind 'ctrl-o:become(_print_selected {+}),enter:become(vim -b {+})' \
  --preview "_generate_preview '$g_opts' '$pattern' {}"

exit 0
