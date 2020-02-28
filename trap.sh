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

# @environment _TRAP__HOOKS_LIST_<signal> Array List of hooks for signal \<signal\>
# @environment _TRAP__HOOKS_DISABLED_<signal> Array Keep track of disable hooks for signal \<signal\>


############
#
# FUNCTIONS
#

# @description Add trap handler.
#   It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__HOOKS_LIST_<signal>`.
# @example
#   trap.add-handler "echo EXIT" TERM
# @arg $1 String Action to call on specified signals: can be shell code or function name
# @arg $@ String Signals to trap
# @return Index of current handler inside the array of handlers for the specified signal: only relevant when providing a single signal
trap_add-handler() {
	local code="$1" ; shift
	local sig idx
	
	for sig in "$@"; do
		local aryname="_TRAP__HOOKS_LIST_${sig^^}"
		declare -n ary_ref="$aryname"
		[[ -v ary_ref ]] || declare -ga "$aryname"='()'
		[[ "$#" = 1 ]] && idx="${#ary_ref[@]}"
		ary_ref+=("$code")
		trap ":trap_handler-helper $sig" $sig
	done
	
	[[ "$#" = 1 ]] && declare -g _TRAP__="$idx"
}
alias trap.add-handler="trap_add-handler"


# @description Disable trap handler with the provided index.
#   Note the the handler is not removed from the stack but only disable, avoiding the renumbering of following handlers and allowing to disable multiple handlers without hassle.
# @example
#   trap.add-handler "echo handler1" EXIT
#   idx=$_TRAP__
#   trap.add-handler "echo handler2" EXIT
#   trap.disable-handler $_TRAP__
#     onexit> is executed only handler2
# @arg $1 String Signal which the handler to disable respond to
# @arg $2 Int Index of the handler to disable
# @exitcodes Standard
trap_disable-handler() {
	local sig="$1" idx="$2"

	local aryname="_TRAP__HOOKS_DISABLED_${sig^^}"
	declare -n ary_ref="$aryname"
	[[ -v ary_ref ]] || declare -ga "$aryname"='()'
	ary_ref[$idx]=0
}
alias trap.disable-handler="trap_disable-handler"


# @internal
# @description Trap handler helper.
#   It is supposed to be used as the action in `trap` built-in bash command.
# @example
#   trap ":trap_handler-helper TERM" TERM
# @arg $1 String Signal to handle
:trap_handler-helper() {
	local sig="$1" idx
	
	declare -n ary_ref="_TRAP__HOOKS_LIST_${sig^^}"
	declare -n ary2_ref="_TRAP__HOOKS_DISABLED_${sig^^}"
	for idx in "${!ary_ref[@]}"; do
		[[ "${ary2_ref[$idx]}" = 0 ]] && continue
		eval "${ary_ref[$idx]}"
	done
#	for code in "${ary_ref[@]}"; do
#		eval "$code"
#	done
	if [[ "$sig" = "INT" ]]; then
		trap - INT
		kill -INT $$
	fi
}
alias :trap.handler-helper=":trap_handler-helper"
