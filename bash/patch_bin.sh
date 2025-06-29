#!/usr/bin/env bash
################################################################################
# Script:   patch_bin.sh                                                       #
# Function:                                                                    #
# Usage:    patch_bin.sh [-h]                                                  #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-24-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

####################
# patch_bin.sh START
####################
help=$(cat <<END
Program description goes here.

Usage: $(basename $0) $USAGE_STR

  -h            Print this help message

END
)

while getopts 'hde:' OPT; do
  case "$OPT" in
    h)
      printf '%s\n' "$help"
      exit 0
      ;;
    d)
      mode='dry-run'
      ;;
    e)
      exclude_list="$OPTARG"
      ;;
    *)
      _usage
      ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
  _invalid_arguments "$@"
fi

bin_dir="$HOME/bin"
git_dir="$HOME/git/shell_scripts"
patch_dir="$HOME/.patches"

( cd "$git_dir" && git checkout main && git pull; )

mapfile -t scripts <<EOF
common.functions
passwordmanager.sh
printrandom.sh
secure.sh
search.sh
visual_grep.sh
grep_preview.sh
new_script.sh
fix_history.sh
setup_workspace.sh
EOF

for sh in "${scripts[@]}"; do
  if echo "$exclude_list" | grep -q "$sh"; then
    continue
  fi
  dir="$patch_dir/$(basename $sh .sh | tr '.' '_')"
  [ -d "$dir" ] || mkdir -p $dir
  patch="$dir/$(date '+%s').patch"
  if [ "$mode" = 'dry-run' ]; then
    diff -Nu $bin_dir/$sh $git_dir/*/$sh
  else
    diff -Nu $bin_dir/$sh $git_dir/*/$sh >$patch &&
      rm $patch || patch -p4 <$patch
  fi
done

chmod 750 $bin_dir/*.sh
chmod 640 $bin_dir/*.functions
chmod 700 $bin_dir/info.sh

exit 0
