#!/bin/zsh

# Decoration (for zsh)
decorate() 
  functions[$1]='
    () { check -l '$@' && '$functions[$1]'; } "$@"
    local ret=$?
    return $ret'

alias check="ruby `pwd`/src/check.rb"
gc() { args="'$*'"; check -l $args; git "$@"; }
