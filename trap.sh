#!/usr/bin/env bash
#github-action genshdoc

# @file trap.sh
# @brief Manage shell traps
# @show-internal
shopt -s expand_aliases

############
#
# GLOBALS
#

# @global _TRAP__HOOKS_LIST_<signal> Array List of hooks for signal \<signal\>
# @global _TRAP__HOOKS_DISABLED_<signal> Array Keep track of disable hooks for signal \<signal\>
# @global _TRAP__HOOKS_LABEL_TO_CODE_<signal> Hash Map label of hook to action code for signal \<signal\>
# @global _TRAP__FUNCTION_HANDLER_CODE String Action to execute for every execution of any function (see function trap.set-function-handler)


############
#
# FUNCTIONS
#

# @description Add trap handler.
#   It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__HOOKS_LIST_<signal>`.
# @alias trap.add-handler
# @arg $1 String Action to call on specified signals: can be shell code or function name
# @arg $@ String Signals to trap
# @example
#   trap.add-handler "echo EXIT" TERM
trap_add-handler() {
	local label="$1" code="$2"
	shift 2
	local sig idx
	
	for sig in "$@"; do
		# array with list of hooks for signal ${sig}
		local aryname="_TRAP__HOOKS_LIST_${sig^^}"
		array.defined? "$aryname" || array.init "$aryname"
		declare -n ary_ref="$aryname"
		
		# hash that map label of hook with action code
		local hashname="_TRAP__HOOKS_LABEL_TO_CODE_${sig^^}"
		hash.defined? "$hashname" || hash.init "$hashname"
		declare -n hash_ref="$hashname"
		
		# update hooks list
		ary_ref+=("$label")
		# map label to action code
		hash_ref["$label"]="$code"
		trap ":trap_handler-helper $sig" $sig
	done
	
}
alias trap.add-handler="trap_add-handler"


trap_remove-handler() {
	local label="$1" sig="$2"
	
	unset "_TRAP__HOOKS_LABEL_TO_CODE_${sig^^}[$label]"
	array.remove "_TRAP__HOOKS_LIST_${sig^^}" "$label"
}
alias trap.remove-handler="trap_remove-handler"

trap_show-handlers() {
	local hook_list idx label signal
	while read hook_list; do
		declare -n ary_ref="$hook_list"
		signal="${hook_list#_TRAP__HOOKS_LIST_}"
		declare -n hash_ref="_TRAP__HOOKS_LABEL_TO_CODE_${signal}"
		for idx in "${!ary_ref[@]}"; do
			label="${ary_ref[$idx]}"
			echo -e "${signal}\t$idx\t$label\t${hash_ref[$label]}"
		done
	done < <( set | grep ^_TRAP__HOOKS_LIST_ 2>/dev/null | cut -d= -f 1 | sort )
}
alias trap.show-handlers="trap_show-handlers"


# @internal
# @description Trap handler helper.
#   It is supposed to be used as the action in `trap` built-in bash command.
# @alias trap.handler-helper
# @arg $1 String Signal to handle
# @example
#   trap ":trap_handler-helper TERM" TERM
:trap_handler-helper() {
	local sig="$1" idx label code
	
	declare -n ary_ref="_TRAP__HOOKS_LIST_${sig^^}"
	declare -n hash_ref="_TRAP__HOOKS_LABEL_TO_CODE_${sig^^}"
	for label in "${ary_ref[@]}"; do
		eval "${hash_ref[$label]}"
	done
	if [[ "$sig" = "INT" ]]; then
		trap - INT
		kill -INT $$
	fi
}
alias :trap.handler-helper=":trap_handler-helper"

# @description Set an handler for every execution of any function.
# @alias trap.set-function-handler
# @arg $1 String Signal to handle
# @example
#   trap.set-function-handler ""
trap_set-function-handler() {
	local code="$1"
	
	declare -g _TRAP__FUNCTION_HANDLER_CODE="$code"
	trap.add-handler ":trap_function-handler-helper" RETURN
	set -o functrace
}
alias trap.set-function-handler="trap_set-function-handler"

:trap_function-handler-helper() {
	array.find_ FUNCNAME :trap_handler-helper
	declare -g _TRAP__FUNCTION_NAME="${FUNCNAME[$__]}"
	eval "$_TRAP__FUNCTION_HANDLER_CODE"
}
alias :trap.function-handler-helper=":trap_function-handler-helper"


