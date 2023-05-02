#!/bin/bash

. ./common.functions

USAGE_STR='[-d file] [-e user:directory]'

_encrypt() {
   if [ ! -d "$1" ] || [ -z "$2" ]; then
      _invalid_argument ${FUNCNAME[0]}
   fi
   tarfile=$(basename $1).tar
   if tar -cvf $tarfile $1; then
      rm -fr $1
   else
      exit $?
   fi
   if gpg -e -r winsl $tarfile; then
      rm $tarfile
   else
      exit $?
   fi
}

_decrypt() {
   if [ "${1##*.}" = "gpg" ]; then
      tarfile=${1%.*}
   elif [ "${1##*.}" != "tar" ]; then
      tarfile=$1.tar
   else
      tarfile=$1
   fi
   if [ ! -f "$tarfile.gpg" ]; then
      _invalid_argument ${FUNCNAME[0]}
   fi
   if gpg -d -o secure.tar --pinentry-mode loopback $tarfile.gpg; then
      rm $tarfile.gpg
   else
      exit $?
   fi
   if tar -xvf $tarfile; then
      rm $tarfile
   else
      exit $?
   fi
}

while getopts 'd:e:' OPT; do
   case "$OPT" in
      d)
         decrypt=$TRUE
         target=$OPTARG
         ;;
      e) 
         if echo "$OPTARG" | grep -q ':'; then
            encrypt=$TRUE
            target=${OPTARG#*:}
            user=${OPTARG%:*}
         fi
         ;;
      *) _usage "$USAGE_STR" ;;
   esac
   if [ $encrypt ] && [ $decrypt ]; then
       _usage "$USAGE_STR"
   fi
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
   _usage "$USAGE_STR"
elif [ $encrypt ]; then
   _encrypt $target $user
elif [ $decrypt ]; then
   _decrypt $target
else
   _usage "$USAGE_STR"
fi

exit 0
