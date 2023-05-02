#!/bin/bash

. ./common.functions

USAGE_STR='[-l length] [-n #_special_chars] [-s special_chars]'
LENGTH=15
NUM_SPECIAL=1
SPECIAL_CHARS='@#$%&_+='

_set_length() {
   if _int_test $1; then
      LENGTH=$1
   else
      exit $?
   fi
}

_set_num_special() {
   if _int_test $1; then
      NUM_SPECIAL=$1 
      LENGTH=$(($LENGTH - $NUM_SPECIAL))
   else
      exit $?
   fi
}

_set_special_chars() {
   SPECIAL_CHARS="$1"
}

while getopts 'l:n:s:' OPT; do
   case "$OPT" in
      l) _set_length $OPTARG ;;
      n) _set_num_special $OPTARG  ;;
      s) _set_special_chars $OPTARG  ;;
      *) _usage "$USAGE_STR" ;;
   esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
   _usage "$USAGE_STR"
fi

{
   </dev/urandom LC_ALL=C grep -ao '[A-Za-z0-9]' | head -n$LENGTH
   for i in $(seq $NUM_SPECIAL); do
      echo ${SPECIAL_CHARS:$((RANDOM % ${#SPECIAL_CHARS})):1} 
   done
} | shuf | tr -d '\n'

exit 0
