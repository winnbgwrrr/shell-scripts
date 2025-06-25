#!/usr/bin/env bash
################################################################################
# Script:   new_script.sh                                                      #
# Function: Create a new bash script file from a template.                     #
# Usage:    new_script.sh [-h]                                                 #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written: 06-11-2025                                                     #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

####################
# new_script.sh START
####################
help=$(cat <<END
Create a new bash script file from a template.

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

snm=${1:?}
if [ -f "$snm" ]; then
  _print_error '%s\n' "$snm already exists"
  exit 99
fi

template=$(cat <<'EOF'
#!/usr/bin/env bash
################################################################################
# Script:                                                                      #
# Function:                                                                    #
# Usage:                                                                  #
#                                                                              #
# Author: Robert Winslow                                                       #
# Date written:                                                      #
#                                                                              #
################################################################################
. $(dirname $0)/common.functions

USAGE_STR='[-h]'

####################
# START
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

if [ $# -ne 0 ]; then
  _invalid_arguments "$@"
fi

exit 0
EOF
)

printf '%s\n' "$template" >"$snm"
sed -i "s/\(^# Script:   \) \{${#snm}\}/\1$snm/" "$snm"
sed -i "s/\(^# Usage:    \) \{${#snm}\}/\1$snm [-h]/" "$snm"
sed -i "s/\(^# Date written: \)/\1$(date '+%m-%d-%Y')/" "$snm"
sed -i "s/^# START/# $snm START/" "$snm"
chmod 750 "$snm"

exit 0
