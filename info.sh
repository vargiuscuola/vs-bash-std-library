#!/usr/bin/env bash
#github-action genshdoc

# if already sourced, return
[[ -v _INFO__LOADED ]] && return || _INFO__LOADED=True

# @file docs.sh
# @brief Include shell libraries modules
# @show-internal
shopt -s expand_aliases
source "$(dirname "${BASH_SOURCE[0]}")/package.sh"

module.import "args"
module.import "module"

# @global _INFO__SHDOC_DIR String Path of the package github.com/vargiuscuola/shdoc (used by the function `info_show` and his alias `info.show`

# @description Show the documentation of the provided function.
# @alias info.show
# @arg $1 String Function name
# @stdout Show the documentation of the provided function
# @example
#   $ info.show args.check-number
info_show() {
  args_check-number 1
  package.load github.com/vargiuscuola/shdoc
  [[ -z "$_INFO__SHDOC_DIR" ]] && { package.get-path_ github.com/vargiuscuola/shdoc ; _INFO__SHDOC_DIR="$__" ; }
  
  local function_name="$1" p
  # if provided name is an alias, recursively expand it to get the function name
  while [[ "alias" = $(type -t -- $function_name) ]] && p=$(alias -- "$function_name" 2>&-); do
    function_name=$(sed -re "s/alias "$function_name"='(\S+).*'$/\1/" <<< "$p")
  done
  local class_name="${function_name%%_*}"
  class_name="${class_name/:/}"
  module_get-class-path_ "$class_name"
  "$_INFO__SHDOC_DIR"/shdoc <${__} | sed -nE "/## $function_name\\(\\)/,/^#{1,2} /p"
}
alias info.show="info_show"
