#!/bin/bash

. $LIB_LOC/common.functions

declare -r USAGE_STR='[-d file] [-e user:directory]'

_encrypt() {
   local directory user
   directory=${1:?}
   user=${2:?}
   if [ ! -d "$1" ]; then
      _print_error "No such directory $directory"
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
   local tarfile
   tarfile=${1:?}
   if [ "${tarfile##*.}" = "gpg" ]; then
      tarfile=${tarfile%.*}
   elif [ "${tarfile##*.}" != "tar" ]; then
      tarfile=$tarfile.tar
   fi
   if [ ! -f "$tarfile.gpg" ]; then
      _print_error "No such file $tarfile.gpg"   
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

_not_both() {
   _print_error 'The encrypt and decrypt options are mutually exclusive'
   exit 99
}

decrypt=0
encrypt=0
while getopts 'd:e:h' OPT; do
   case "$OPT" in
      d)
         if [ $encrypt -eq 1 ]; then
            _not_both
         fi
         decrypt=1
         target=$OPTARG
         ;;
      e) 
         if [ $decrypt -eq 1 ]; then
            _not_both
         fi
         if echo "$OPTARG" | grep -q ':'; then
            encrypt=1
            target=${OPTARG#*:}
            user=${OPTARG%:*}
         fi
         ;;
      h|*)
         _usage "$USAGE_STR"
         ;;
   esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
   _invalid_arguments "$@"
elif [ $encrypt -eq 1 ]; then
   _encrypt $target $user
elif [ $decrypt -eq 1 ]; then
   _decrypt $target
else
   _invalid_arguments "$@"
fi

exit 0
