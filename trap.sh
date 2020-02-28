#!/usr/bin/env bash
#github-action genshdoc

# @file trap.sh
# @brief Manage shell traps
# @show-internal
shopt -s expand_aliases

############
#
# ENVIRONMENT
#

# @environment _TRAP__SIGNAL_HOOKS_<signal> Array List of hooks for signal <signal>


############
#
# FUNCTIONS
#

# @description Add trap handler
# @example
#  trap.add-handler "echo EXIT" TERM
# @arg $1 string Shell code or function to call on signal
# @arg $@ string Signals to trap
# @return Index of 
trap_add-handler() {
	local code="$1" ; shift
	local sig idx
	
	for sig in "$@"; do
		local aryname="_TRAP__SIGNAL_HOOKS_${sig^^}"
		declare -n ary_ref="$aryname"
		[[ -v ary_ref ]] || declare -g "$aryname"='()'
		[[ "$#" = 1 ]] && idx="${#ary_ref[@]}"
		ary_ref+=("$code")
		trap ":trap_handler-helper $sig" $sig
	done
	
	[[ "$#" = 1 ]] && declare -g _TRAP__="$idx"
}
alias trap.add-handler="trap_add-handler"


# @internal
# @description Trap handler helper.
#  It is supposed to be used as action in `trap` built-in bash command
# @example
#  trap.handler-helper TERM
# @arg $1 string Function to call
# @arg $@ string Signals to trap
# @return 
:trap_handler-helper() {
	local sig="$1"
	
	local aryname="_TRAP__SIGNAL_HOOKS_${sig^^}"
	declare -n ary_ref="$aryname"
	for code in "${ary_ref[@]}"; do
		eval "$code"
	done
	if [[ "$sig" = "INT" ]]; then
		trap - INT
		kill -INT $$
	fi
}
alias :trap.handler-helper=":trap_handler-helper"
