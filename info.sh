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

# @global _INFO__SHDOC_DIR String Path of the package github.com/vargiuscuola/shdoc (used by the function `info_show` and his alias `info.show`

# @description List the functions of the provided class, which must be already loaded with `module.import` or at least `source`-ed.
# @alias info.list-class-functions
# @arg $1 String Class name
# @stdout List of functions which are part of the provided class
# @example
#   $ info.list-class-functions args
#   args.check-number
#   args.parse
#   args_check-number
#   args_parse
#   args_to_str_
info_list-class-functions() {
	args_check-number 1
	alias | sed -E 's/^alias // ; s/=.*//' | grep -- "^${1}\\."					# aliases
	declare -F | sed -E 's/^declare -[^[:space:]]+ //' | grep -- "^${1}_"		# functions
}
alias info.list-class-functions="info_list-class-functions"

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
	# if provided is an alias, recursively expand it to get the function name
	while [[ "alias" = $(type -t -- $function_name) ]] && p=$(alias -- "$function_name" 2>&-); do
		function_name=$(sed -re "s/alias "$function_name"='(\S+).*'$/\1/" <<< "$p")
	done
	local class_name="${function_name%%_*}"
	class_name="${class_name/:/}"
	echo class_name=$class_name
#	"$_INFO__SHDOC_DIR"/shdoc \<${}
}
alias info.show="info_show"
