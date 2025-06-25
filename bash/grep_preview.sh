################################################################################
# Script:   grep_preview.sh                                                    #
# Function: Print one or more snippets from a file where a pattern was found.  #
# Usage:    grep_preview.sh [-h] [-i] [-w] pattern file                        #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-25-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h] [-i] [-w] pattern file'
DOC_PAGE="$CONFLUENCE/TOOL/$(basename $0)"

####################
# grep_preview.sh START
####################
help=$(cat <<END
Print one or more snippets from a file where a pattern was found.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message
  -i            Case insensitive pattern matching
  -w            Force PATTERN to match only whole words

For additional information please reference:

  $DOC_PAGE
END
)

g_opts='-'
while getopts 'hiw' OPT; do
  case "$OPT" in
    h)
      printf '%s\n' "$help"
      exit 0
      ;;
    i)
      g_opts="${g_opts}i"
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

if [ $# -ne 2 ]; then
  _invalid_arguments "$@"
fi

pattern="${1:?}"
file_name="${2:?}"
snip_size=7

mapfile -t line_nums < <(grep ${g_opts}n "$pattern" $file_name |
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
    cat -n $file_name | sed -n "$bln,${eln}p" |
      grep --color=always ${g_opts}E "$pattern|$" |
      awk '{printf "\033[38;5;187m%s\033[m%s\n", $1, substr($0, 7)}'
  elif [ $ln -lt $(($eln+$snip_size)) ]; then
    eln=$(($ln+$snip_size))
  else
    cat -n $file_name | sed -n "$bln,${eln}p" |
      grep --color=always ${g_opts}E "$pattern|$" |
      awk '{printf "\033[38;5;187m%s\033[m%s\n", $1, substr($0, 7)}'
    tput setaf 67
    printf '\n %s\n\n' "$(for i in {1..80}; do printf '%c' '~'; done)"
    tput sgr0
    bln=$(($ln-$snip_size))
    eln=$(($ln+$snip_size))
  fi
done

exit 0
