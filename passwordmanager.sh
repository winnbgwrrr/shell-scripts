#!/bin/bash

. ./common.functions

USAGE_STR='[user]'

if [ $# -ne 1 ]; then
   _usage "$USAGE_STR"
fi

toplevel='/c/users/winsl'
user="$1"
secdir='Documents/secure'
outfile="$secdir/.passfile"
encfile='secure.tar.gpg'
special_chars='@#$%&_+='

_start() {
   cd $toplevel
   if [ -f "$encfile" ]; then
      for i in 1 2 3; do
         secure.sh -d $encfile
         if [ $? -eq 0 ]; then
            break
         elif [ $i -eq 3]; then
            exit 101
         fi
      done
   fi
}

_stop() {
   secure.sh -e "$user:$secdir"
   cd -
}

_menu() {
   local menuopts=("$@")
   _display_menu "$@"
   local usrin lastopt=$((${#menuopts[@]}-1))
   read -n ${#lastopt} -p "Enter Choice [1-$lastopt] " usrin
   case $usrin in
      [0-9]*) _${menuopts[$usrin],} ;;
      [Qq]*) _quit ;;
      *) clear
         printf $fmt_sn "$usrin is not a recognized option."
         ;;
   esac
}

_main_menu() {
   printf $fmt_sn 'MAIN MENU'
   if [ -f "$outfile" ]; then
      _menu 'Select one of the following options' 'List' 'Add' 'Quit'
   else
      _menu 'Select one of the following options' 'Add' 'Quit'
   fi
   _main_menu
}

_list() {
   clear
   printf $fmt_sn 'ACCOUNT LIST'
   declare -a listopts=('Please choose one of the following accounts (or press any other key to return to the main menu)')
   for line in $(cat $outfile); do
      listopts+=(${line%%:*})
   done
   listopts+=('Back to Main Menu')
   _display_menu "${listopts[@]}" 
   local usrin lastopt=$((${#listopts[@]}-1))
   read -n ${#lastopt} -p "Enter Choice [1-$lastopt] " usrin
   case $usrin in
      $lastopt)
         clear
         _main_menu
         ;;
      [0-9]*) _select $usrin ;;
      [Qq]*) _quit ;;
      *)
         clear
         printf $fmt_sn "$usrin is not a recognized option."
         ;;
   esac
   _list
}

_add() {
   clear
   read -p 'Please enter the name of this account: ' accname
   if [ -f "$outfile" ] && grep -q "$accname" $outfile; then
      clear
      _print_error 'This name already exists.'
      return 81
   fi
   read -p 'Please enter the user name for this account: ' usrname
   read -p 'Please specify the password length (press enter for default) : ' length
   read -p 'Please specify the number of special characters for the password (press enter for default) : ' numspec
   read -p "Please specify any special characters ($special_chars) that should not be used (press enter for default): " excspec
   local args
   if [ -n "$length" ]; then
      args=" -l $length"
   fi
   if [ -n "$numspec" ]; then
      args="$args -n $numspec"
   fi
   if [ -n "$excspec" ]; then
      spchars=$(echo "$special_chars" | tr -d "$excspec")
      args="$args -s $spchars"
   fi
   str=$(printrandom.sh $args)
   rc=$?
   if [ $rc -eq 0 ]; then
      echo "$accname:$length:$numspec:$espchars:$usrname/$str" >>$outfile
   else
      clear
      _print_error 'An error ocurred while generating a new password.'
      return $rc
   fi
   accinfo=$(grep "^$accname" $outfile)
   _show
   clear
}

_quit() {
   exit 0
}

_select() {
   clear
   if [ -z "$1" ]; then
      _invalid_argument ${FUNCNAME[0]}
   fi
   linenum=$1
   accinfo=$(sed "${1}q;d" $outfile)
   accname=${accinfo%%:*}
   _menu "Select on of the following actions for account $accname" 'Update' 'Delete' 'Show'
   _list
}

_update() {
   length=$(echo "$accinfo" | cut -d : -f 2)
   numspec=$(echo "$accinfo" | cut -d : -f 3)
   excspec="$(echo "$accinfo" | cut -d : -f 4)"
   str=$(printrandom.sh -l $length -n $numspec -e "$excspec")
   rc=$?
   if [ $rc -eq 0 ]; then
      sed -i "s/^\($accname.*\/\).*/\1$str/" $outfile
   else
      clear
      _print_error 'An error ocurred while generating a new password.'
      return $rc
   fi
   printf $fmt_sn "$accname updated."
   accinfo=$(sed "${linenum}q;d" $outfile)
   _show
}

_delete() {
   clear
   local usrin
   read -p "Are you sure that you want to delete $accname? " usrin
   case "$usrin" in
      [Yy]*)
         sed -i "${linenum}d" $outfile
         printf $fmt_sn "$accname deleted."
         read -n 1 -p 'Press any key to continue'
   esac
}

_show() {
   clear
   local creds=${accinfo##*:}
   usrname=$(echo "$creds" | cut -d / -f 1)
   str=$(echo "$creds" | cut -d / -f 2)
   _print_caps "$accname"
   printf $fmt_tsn "$usrname" 
   printf $fmt_tsn "$str" 
   read -n 1 -p 'Press any key to continue'
}

trap _stop EXIT
_start
clear
_main_menu
