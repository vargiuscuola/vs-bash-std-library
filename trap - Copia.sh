#!/usr/bin/env bash
#github-action genshdoc

# @file trap.sh
# @brief Manage shell traps
# @show-internal
shopt -s expand_aliases

module.import "main"

############
#
# GLOBALS
#

# @global _TRAP__HOOKS_LIST_<signal> Array List of hooks for signal \<signal\>
# @global _TRAP__HOOKS_LABEL_TO_CODE_<signal> Hash Map label of hook to action code for signal \<signal\>
# @global _TRAP__FUNCTION_HANDLER_CODE String Action to execute for every execution of any function (see function trap.set-function-handler)
# @global _TRAP__FUNCTION_NAME String Name of the current function executed, set if a function handler is enabled through the `trap.set-function-handler` function
# @global _TRAP__CURRENT_COMMAND String Laso command executed: available when command trace is enabled through `trap.enable-trace` function
# @global _TRAP__LAST_COMMAND String Previous command executed: available when command trace is enabled through `trap.enable-trace` function
# @global _TRAP__TEMP_LINENO Number Temporary line number, assigned to $_TRAP__LAST_LINENO only when needed
# @global _TRAP__LINENO Number Line number of current command: available when command trace is enabled through `trap.enable-trace` function
# @global _TRAP__LAST_LINENO Number Line number of previous command: available when command trace is enabled through `trap.enable-trace` function
# @global _TRAP__EXITCODE_<signal> Number Exit code received by the trap handler for signal \<signal\>
declare -g _TRAP__FUNCTION_STACK=()
declare -g _TRAP__SUSPEND_COMMAND_TRACE=""

############
#
# FUNCTIONS
#

# @description Test whether a trap with provided label for provided signal is defined.
# @alias trap.has-handler?
# @arg $1 String Label of the handler
# @arg $2 String Signal to which the handler responds to
# @exitcodes Boolean ($True or $False)
# @example
#   trap.has-handler? LABEL TERM
trap_has-handler?() {
	local label="$1" sig="$2"
	hash.has-key? "_TRAP__HOOKS_LABEL_TO_CODE_${sig^^}" "$label"
}
alias trap.has-handler?="trap_has-handler?"



# @description Add trap handler.
#   It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__HOOKS_LIST_<signal>`.
# @alias trap.add-handler
# @arg $1 String Descriptive label to associate to the added trap handler
# @arg $2 String Action code to call on specified signals: can be shell code or function name
# @arg $@ String Signals to trap
# @exitcode 0 On success
# @exitcode 1 If label of the new trap handler already exists (or of one of the new trap handlers, in case of multiple signals)
# @example
#   trap.add-handler LABEL "echo EXIT" TERM
trap_add-handler() {
	parse.check-args-number $# 3
	local label="$1" code="$2"
	shift 2
	local sig idx addcode ret=0
	
	for sig in "$@"; do
		sig="${sig^^}"
		local hashname="_TRAP__HOOKS_LABEL_TO_CODE_${sig}"
		hash.has-key? "$hashname" "$label" && { ret=1 ; continue ; }
		
		# array with list of hooks for signal ${sig}
		local aryname="_TRAP__HOOKS_LIST_${sig}"
		array.defined? "$aryname" || array.init "$aryname"
		declare -n ary_ref="$aryname"
		
		# hash that map label of hook with action code
		hash.defined? "$hashname" || hash.init "$hashname"
		declare -n hash_ref="$hashname"
		
		# update hooks list
		ary_ref+=("$label")
		# map label to action code
		hash_ref["$label"]="$code"
		
		# if $sig == DEBUG, store info about line number and current command
		[[ "$sig" = DEBUG ]] && addcode='_TRAP__TEMP_LINENO="$LINENO" ; '
		trap "${addcode}_TRAP__EXITCODE_${sig}=\$? ; :trap_handler-helper $sig" $sig
	done
	return "$ret"
}
alias trap.add-handler="trap_add-handler"


# @description Enable command tracing by setting a trap on signal `DEBUG` that set the global variables $_TRAP__LAST_COMMAND, $_TRAP__CURRENT_COMMAND and $_TRAP__LINENO.
# @alias trap.enable-trace
trap_enable-trace() {
	_TRAP__IS_COMMAND_TRACE_ENABLED=$True
	trap.add-handler _TRAP_COMMAND_EXEC '' DEBUG
	set -o functrace
}
alias trap.enable-trace="trap_enable-trace"


# @description Add an error handler called on EXIT signal.
#   To force the exit on command fail, the shell option `-e` is enabled. The ERR signal is not used instead because it doesn't allow to catch failing commands inside functions.
# @alias trap.add-error-handler
# @arg $1 String Label of the trap handler
# @arg $2 String Action code to call on EXIT signal: can be shell code or a function name
# @example
#   trap.add-error-handler CHECKERROR 'echo ERROR Command \"$_TRAP__CURRENT_COMMAND\" [line $_TRAP__LINENO] on function $_TRAP__FUNCTION_NAME\(\)'
#   trap.add-error-handler CHECKERR trap.show-error
trap_add-error-handler() {
	local label="$1" code="$2"
	
	[[ "$_TRAP__IS_COMMAND_TRACE_ENABLED" != $True ]] && trap.enable-trace
	set -e
##	trap.is-function-handler? || trap.set-function-handler ""
	trap_add-handler "$label" "[[ \"\$_TRAP__EXITCODE_EXIT\" != 0 ]] && $code" EXIT
}
alias trap.add-error-handler="trap_add-error-handler"


# @description Remove trap handler.
# @alias trap.remove-handler
# @arg $1 String Label of the trap handler to delete (as used in `trap.add-handler` function)
# @arg $2 String Signal to which the trap handler is currently associated
# @example
#   trap.remove-handler LABEL TERM
trap_remove-handler() {
	local label="${1^^}" sig="$2"
	
	unset "_TRAP__HOOKS_LABEL_TO_CODE_${sig}[$label]"
	array.remove "_TRAP__HOOKS_LIST_${sig}" "$label"
}
alias trap.remove-handler="trap_remove-handler"


# @description Show all trap handlers.
# @alias trap.show-handlers
# @stdout List of trap handlers, with the following columns separated by tab: `signal`, `index`, `label`, `action code`
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
	local current_command="$BASH_COMMAND"
	local sig="${1^^}" idx label code
echo STACK TRACE "${FUNCNAME[@]}" COMMAND=$current_command SIG=$sig
#	[[ ! "${FUNCNAME[1]}" =~ ^:trap ]] && ! list.include? :trap_handler-helper "${FUNCNAME[@]:1}"
	while [[ "$sig" = DEBUG && "$_TRAP__TEMP_LINENO" != 1 && "$_TRAP__IS_COMMAND_TRACE_ENABLED" = $True &&
		( "$_TRAP__LAST_LINENO" != "$_TRAP__TEMP_LINENO" || "$_TRAP__CURRENT_COMMAND" != "$current_command"  ) ]]; do
		array.find-indexes_ FUNCNAME :trap_handler-helper
		[[ "${#__a}" -gt 0 ]] && local current_funcname_idx="${__a[-1]}" || local current_funcname_idx=0
		local new_current_funcname="${FUNCNAME[${current_funcname_idx}]}"
		# if trap.suspend-trace is called, enable the trace suspension keeping track of the current function name and his index in the stack trace 
		if [[ "$current_command" = ": trap.suspend-trace" ]]; then
			_TRAP__SUSPEND_COMMAND_TRACE=$new_current_funcname
			_TRAP__SUSPEND_COMMAND_TRACE_IDX="$(( $current_funcname_idx-${#FUNCNAME[@]} ))"
			break
		fi
		if [[ -n "$_TRAP__SUSPEND_COMMAND_TRACE" ]]; then
			# if trace is suspended, check if the function that suspended the trace is still running by checking if that function is still on the same position of the stack trace
			[[ "${FUNCNAME[$_TRAP__SUSPEND_COMMAND_TRACE_IDX]}" = "$_TRAP__SUSPEND_COMMAND_TRACE" ]] && break
			# otherwise end the trace suspension and keep tracing again
			_TRAP__SUSPEND_COMMAND_TRACE=""
		fi
		[[ "$current_command" = "$_TRAP__CURRENT_COMMAND" && "${_TRAP__CURRENT_COMMAND/ */}" = "$new_current_funcname" ]] && break
		_TRAP__LAST_LINENO="$_TRAP__LINENO"
		_TRAP__LINENO="$_TRAP__TEMP_LINENO"
		_TRAP__LAST_COMMAND="$_TRAP__CURRENT_COMMAND"
		_TRAP__CURRENT_COMMAND="$current_command"
		_TRAP__CURRENT_FUNCTION="$new_current_funcname"
		[[ "${#__a}" -gt 0 ]] && _TRAP__FUNCTION_STACK=("${FUNCNAME[@]:${__a[-1]}}") || _TRAP__FUNCTION_STACK=("${FUNCNAME[@]}")
		if [[ "$_TRAP__IS_TRACE" = $True ]]; then
			cat <<EOD
#== Debugger Trace
### Line number[\$_TRAP__LINENO]=$_TRAP__LINENO
### Previous line number[\$_TRAP__LAST_LINENO]=$_TRAP__LAST_LINENO
### Current command[\$_TRAP__CURRENT_COMMAND]=$_TRAP__CURRENT_COMMAND
### Previous command[\$_TRAP__LAST_COMMAND]=$_TRAP__LAST_COMMAND
### Current function[\$_TRAP__CURRENT_FUNCTION]=$_TRAP__CURRENT_FUNCTION
### Stack trace[\$_TRAP__FUNCTION_STACK[@]]=${_TRAP__FUNCTION_STACK[@]}
EOD
			read -p "### Press Enter to continue... " </dev/tty
		fi
		break
	done
	
	declare -n ary_ref="_TRAP__HOOKS_LIST_${sig}"
	declare -n hash_ref="_TRAP__HOOKS_LABEL_TO_CODE_${sig}"
	for label in "${ary_ref[@]}"; do
		eval "${hash_ref[$label]}"
	done
	if [[ "$sig" = "INT" ]]; then
		trap - INT
		kill -INT $$
	fi
}
alias :trap.handler-helper=":trap_handler-helper"

trap_step-trace-start() {
	declare -g _TRAP__IS_TRACE=$True
}
alias trap.step-trace-start="trap_step-trace-start"

trap_step-trace-stop() {
	declare -g _TRAP__IS_TRACE=$False
}
alias trap.step-trace-stop="trap_step-trace-stop"

# @description Show error information.
# @alias trap.show-trace-error
# @arg $1 Number[$_TRAP__EXITCODE_EXIT] Exit code: defaults to the exit code of EXIT trap handler
# @example
#   trap.add-error-handler CHECKERR trap.show-trace-error
trap_show-trace-error(){
	[[ "$1" = "--exit" ]] && { local is_exit=$True ; shift ; }
	local exitcode="${1:-$_TRAP__EXITCODE_EXIT}"
	[[ "$#" = 2 ]] && local msg=$'\n'"    Error message: $2"
	if [[ "${exitcode:-0}" != 0 ]]; then
		cat <<EOD
Error occurred:${msg}
    Command: $_TRAP__CURRENT_COMMAND
    Function: $_TRAP__CURRENT_FUNCTION
    Stack trace: ${_TRAP__FUNCTION_STACK[@]}
    Line number: $_TRAP__LINENO
    Exit code: $exitcode
EOD
		awk 'NR>L-4 && NR<L+4 { printf "%-5d%3s%s\n",NR,(NR==L?">>>":""),$0 }' L=$_TRAP__LINENO $0
		[[ "$is_exit" = $True ]] && exit $exitcode
	fi
}
alias trap.show-trace-error="trap_show-trace-error"