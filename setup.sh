#!/bin/zsh

alias check="ruby `pwd`/src/check.rb"

#echo >&2 "Calling function '$1' with $# arguments"
#echo >&2 "function '$1' returned with status $ret"

decorate() 
  functions[$1]='
    () { check -l '$@' && '$functions[$1]'; } "$@"
    local ret=$?
    return $ret'

gc() { args="'$*'"; check -l $args; git "$@"; }
