#!/usr/bin/env bash
#github-action genshdoc

# if already sourced, return
[[ -v _TRAP__LOADED ]] && return || _TRAP__LOADED=True

# @file trap.sh
# @brief Manage shell traps and provide stack trace functionalities.
# @description It provide two features: the management of trap handlers (with the support of multiple handlers per signal) and stack trace funtionalities for debugging purposes.  
#   The stack trace allow to set which functions to trace, giving an extensive report of the code execution including:
#   * current and previous line number
#   * current and previous command
#   * current function
#   * function stack
#   Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))
# @show-internal
shopt -s expand_aliases

module.import "main"
module.import "args"

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
# @global _TRAP__SUSPEND_COMMAND_TRACE String The name of the function for which to suspend the debugger trace functionality (set by the use of the special syntax `: trap_suspend-trace`)

# @global _TRAP__SUSPEND_COMMAND_TRACE_IDX Number The position inside the stack trace of the suspended function stored in the global variable `_TRAP__SUSPEND_COMMAND_TRACE`
declare -g _TRAP__SUSPEND_COMMAND_TRACE="" _TRAP__SUSPEND_COMMAND_TRACE_IDX=""

# @global _TRAP__FUNCTION_STACK Array An array of functions storing the stack trace
declare -ga _TRAP__FUNCTION_STACK=()

# @global _TRAP__LINENO_STACK Array An array of numbers storing the line numbers inside each function in the stack trace respectively
declare -ga _TRAP__LINENO_STACK=()

# @global _TRAP__STEP_INTO_FUNCTIONS String The name of the function inside which activate a debugging trace with a step into logic (set by the functions `trap.step-trace-add`, `trap.step-trace-remove` and `trap.step-trace-reset`)
declare -ga _TRAP__STEP_INTO_FUNCTIONS=()

# @global _TRAP__STEP_OVER_FUNCTIONS String The name of the function inside which activate a debugging trace with a step over logic (set by the functions `trap.step-trace-add`, `trap.step-trace-remove` and `trap.step-trace-reset`)
declare -ga _TRAP__STEP_OVER_FUNCTIONS=()

############
#
# FUNCTIONS
#

# @description Test whether a trap with provided label for the provided signal is defined.
# @alias trap.has-handler
# @arg $1 String Label of the handler
# @arg $2 String Signal to which the handler responds to
# @exitcodes Boolean ($True or $False)
# @example
#   $ trap.has-handler LABEL TERM
trap_has-handler() {
  args_check-number 2
  hash.has-key "_TRAP__HOOKS_LABEL_TO_CODE_${2^^}" "$1"
}
alias trap.has-handler="trap_has-handler"

# @description Add a trap handler.  
#   It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__HOOKS_LIST_<signal>`.
# @alias trap.add-handler
# @arg $1 String Descriptive label to associate to the added trap handler
# @arg $2 String Action code to be called on specified signals: can be shell code or function name
# @arg $@ String Signals to trap
# @exitcode 0 On success
# @exitcode 1 If label of the new trap handler already exists (or of one of the new trap handlers, in case of multiple signals)
# @example
#   $ trap.add-handler LABEL "echo EXIT" TERM
trap_add-handler() {
  args_check-number 3 -
  local label="$1" code="$2"
  shift 2
  local sig idx addcode ret=0
  
  for sig in "$@"; do
    sig="${sig^^}"
    local hashname="_TRAP__HOOKS_LABEL_TO_CODE_${sig}"
    hash.defined "$hashname" || hash.init "$hashname"
    hash.has-key "$hashname" "$label" && { ret=1 ; continue ; }
    
    # array with list of hooks for signal ${sig}
    local aryname="_TRAP__HOOKS_LIST_${sig}"
    array.defined "$aryname" || array.init "$aryname"
    declare -n ary_ref="$aryname"
    
    # hash that map label of hook with action code
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


# @description Enable command tracing by setting a null trap for signal `DEBUG` with the purpose of collecting the data related to the stack trace.  
#   The actual management of the stack trace is done by [:trap_handler-helper()](#trap_handler-helper)
# @alias trap.enable-trace
trap_enable-trace() {
  _TRAP__IS_COMMAND_TRACE_ENABLED=$True
  trap.add-handler _TRAP_COMMAND_EXEC '' DEBUG
  set -o functrace
}
alias trap.enable-trace="trap_enable-trace"

# @description Check whether the debug trace is enabled (see [trap_enable-trace](#trap_enable-trace)).
# @alias trap.is-trace-enabled
trap_is-trace-enabled() {
  [[ "$_TRAP__IS_COMMAND_TRACE_ENABLED" = $True ]]
}
alias trap.is-trace-enabled="trap_is-trace-enabled"


# @description Set an handler for the EXIT signal useful for error management.  
#   To be able to catch every error, the shell option `-e` is enabled. The ERR signal is not used instead because it doesn't allow to catch failing commands inside functions.
# @alias trap.add-error-handler
# @arg $1 String Label of the trap handler
# @arg $2 String Action code to call on EXIT signal: can be shell code or a function name
# @example
#   $ trap.add-error-handler CHECKERROR 'echo ERROR Command \"$_TRAP__CURRENT_COMMAND\" [line $_TRAP__LINENO] on function $_TRAP__CURRENT_FUNCTION\(\)'
#   $ trap.add-error-handler CHECKERR trap.show-stack-trace
trap_add-error-handler() {
  args_check-number 2
  local label="$1" code="$2"
  
  [[ "$_TRAP__IS_COMMAND_TRACE_ENABLED" != $True ]] && trap.enable-trace
  set -e
  trap_add-handler "$label" '[[ "$_TRAP__EXITCODE_EXIT" != 0 ]] && '"$code || true" EXIT
}
alias trap.add-error-handler="trap_add-error-handler"


# @description Remove a trap handler.
# @alias trap.remove-handler
# @arg $1 String Label of the trap handler to delete (as used in [trap_add-handler()](#trap_add-handler))
# @arg $2 String Signal to which the trap handler is currently associated
# @example
#   $ trap.remove-handler LABEL TERM
trap_remove-handler() {
  args_check-number 2
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


# @description Suspend debug trace for the calling function and the inner ones.  
#   It must be called with the no-op bash built-in command, as in `: trap_suspend-trace` or `: trap.suspend-trace`: it means the function will not be actually called, but that syntax will be
#   intercepted and treated by the debug trace manager. That allows to suspend the debug trace immediately, differently than calling a real `trap_suspend-trace` function which will fulfill that
#   request too late (for the purpose of not tampering with the stack).
# @alias trap.suspend-trace
# @example
#   func_not_to_be_traced() {
#     : trap_suspend-trace
#     # the following commands and functions are not traced 
#     func2
#   }
trap_suspend-trace() { : trap_suspend-trace ; }

# @internal
# @description Trap handler helper.  
#   It's used as the action in `trap` built-in bash command, and take care of dispatching the signals to the users' handlers set by [trap_add-handler](#trap_add-error-handler) or [trap_add-error-handler](#trap_add-handler).
# @alias trap.handler-helper
# @arg $1 String Signal to handle
# @example
#   $ trap ":trap_handler-helper TERM" TERM
:trap_handler-helper() {
  args_check-number 1
  local current_command="$BASH_COMMAND" exitcode="$?"
  local __backup="$__" # backup of global variable $__
  local sig="${1^^}" idx label code input
  while [[ "$sig" = DEBUG && "$_TRAP__TEMP_LINENO" != 1 && "$_TRAP__IS_COMMAND_TRACE_ENABLED" = $True &&          # if it's a DEBUG signal and trace is enabled and
    ( "$_TRAP__LAST_LINENO" != "$_TRAP__TEMP_LINENO" || "$_TRAP__CURRENT_COMMAND" != "$current_command"  ) ]] &&  # if current command or line number is changed and
    ! list.include :trap_handler-helper "${FUNCNAME[@]:1}"; do                # if the stack trace, apart the current function, doesn't include :trap_handler-helper
                                                                              # then provice tracing functionality...
    array.find-indexes_ FUNCNAME :trap_handler-helper
    local new_current_funcname="${FUNCNAME[1]}"
    # if trap.suspend-trace is called, enable the trace suspension keeping track of the current function name and his index in the stack trace
    if [[ -z "$_TRAP__SUSPEND_COMMAND_TRACE" && ( "$current_command" = ": trap_suspend-trace" || "$current_command" = ": trap.suspend-trace" ) ]]; then
      _TRAP__SUSPEND_COMMAND_TRACE=$new_current_funcname
      _TRAP__SUSPEND_COMMAND_TRACE_IDX="$(( 1-${#FUNCNAME[@]} ))"
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
    if (( ${#_TRAP__LINENO_STACK[@]} == 0 )); then
      _TRAP__LINENO_STACK=( $(printf -- '- %.0s' $( seq 1 $((${#FUNCNAME[@]}-1)) ) ) )
    elif (( ${#FUNCNAME[@]}-1 < ${#_TRAP__FUNCTION_STACK[@]} )); then
      _TRAP__LINENO_STACK=( "${_TRAP__LINENO_STACK[@]:$(( ${#_TRAP__LINENO_STACK[@]}-${#FUNCNAME[@]}+1 ))}" )
    elif (( ${#FUNCNAME[@]}-1 > ${#_TRAP__FUNCTION_STACK[@]} )); then
      _TRAP__LINENO_STACK=( "" "${_TRAP__LINENO_STACK[@]}" )
    fi
    _TRAP__LINENO_STACK[0]=$_TRAP__LINENO
    _TRAP__FUNCTION_STACK=("${FUNCNAME[@]:1}")
    if [[ "$_TRAP__IS_TRACE" = $True ]] && (
        (( "${#_TRAP__STEP_INTO_FUNCTIONS[@]}" == 0 && "${#_TRAP__STEP_OVER_FUNCTIONS[@]}" == 0 )) ||
        ( [[ "${#_TRAP__STEP_INTO_FUNCTIONS[@]}" -gt 0 ]] && array.intersection_ FUNCNAME _TRAP__STEP_INTO_FUNCTIONS ) ||
        ( [[ "${#_TRAP__STEP_OVER_FUNCTIONS[@]}" -gt 0 ]] && array.find_ _TRAP__STEP_OVER_FUNCTIONS "${FUNCNAME[1]}" )
      ); then
      local opt_step
      [[ "${_TRAP__CURRENT_COMMAND}" =~ ^[a-zA-Z_:?.\-] ]] &&
        opt_step=$'\n'\
"    [i] Step into \"${_TRAP__CURRENT_COMMAND/ */}\""$'\n'\
"    [o] Step over \"${_TRAP__CURRENT_COMMAND/ */}\""
      echo -ne "${Yellow}#== Debugger Trace${Color_Off}
### Line number           $_TRAP__LINENO
### Previous line number  $_TRAP__LAST_LINENO
### Current command       $_TRAP__CURRENT_COMMAND
### Previous command      $_TRAP__LAST_COMMAND
### Current function      $_TRAP__CURRENT_FUNCTION
### Function stack        ${_TRAP__FUNCTION_STACK[@]}
### Line number stack     ${_TRAP__LINENO_STACK[@]}
$( get_ext_color 141 )#######${Color_Off}
    [e] End step trace${opt_step}
    [s] Suspend trace for current function \"${_TRAP__CURRENT_FUNCTION}\"
    [ENTER] Continue
$( get_ext_color 141 )### Choose one of the above options:${Color_Off} "
      read -N1 input </dev/tty
      case "${input,,}" in
        e) trap_step-trace-stop ;;
        i) trap_step-trace-add --step-into "${_TRAP__CURRENT_COMMAND/ */}" ;;
        o) trap_step-trace-add --step-over "${_TRAP__CURRENT_COMMAND/ */}" ;;
        s)
          _TRAP__SUSPEND_COMMAND_TRACE="$_TRAP__CURRENT_FUNCTION"
          _TRAP__SUSPEND_COMMAND_TRACE_IDX="$(( 1-${#FUNCNAME[@]} ))"
        ;;
      esac
      [[ "$input" != $'\n' ]] && echo
    fi
    break
  done
  
  declare -n ary_ref="_TRAP__HOOKS_LIST_${sig}"
  declare -n hash_ref="_TRAP__HOOKS_LABEL_TO_CODE_${sig}"
  for label in "${ary_ref[@]}"; do
    eval "${hash_ref[$label]}" || true
  done
  if [[ "$sig" = "INT" ]]; then
    trap - INT
    kill -INT $BASHPID
  fi
  declare -g __="${__backup}"      # restore of global variable $__
}
alias :trap.handler-helper=":trap_handler-helper"

# @description Configure the step trace adding the provided functions to the list of step-trace enabled functions.  
#    It's possible to specify two types of step trace for every provided function: `step into` will enable the step trace for every command in the function and will be inherited by the called functions; `step over` will enable the step trace for every command in the function, but the debug trace functionality will not be inherited by the called functions.
# @alias trap.step-trace-add
# @arg $@ String Function name or alias to function for which enable the stack trace, in `step into` or `step over` mode depending of the closest preceding option, respectively `--step-into` or `--step-over` (step into mode is used by default if no option is specified)
# @opt --step-into Enable the step into debug trace for the following functions
# @opt --step-over Enable the step over debug trace for the following functions
# @example
#   $ trap.step-trace-add func1    # Add func1 to the list of step into debug traced functions
#   $ trap.step-trace-add --step-over func1 func2 --step-into func3    # Add func1 and func2 to the list of step over debug traced functions, and func3 to the list of step into debug traced functions
trap_step-trace-add() {
  args_check-number 1 -
  local type_trace=into
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --step-over) type_trace=over ; shift ;;
      --step-into) type_trace=into ; shift ;;
      *)
        main_dereference-alias_ "$1" ; local func_to_add="$__"
        [[ "$type_trace" = into ]] && declare -n ary_ref=_TRAP__STEP_INTO_FUNCTIONS || declare -n ary_ref=_TRAP__STEP_OVER_FUNCTIONS
        array.find_ ary_ref "$func_to_add" || ary_ref+=( "$func_to_add" )
        shift 1
      ;;
    esac
  done
}
alias trap.step-trace-add="trap_step-trace-add"

# @description Reset the step trace function list.
# @alias trap.step-trace-reset
trap_step-trace-reset() {
  _TRAP__STEP_INTO_FUNCTIONS=()
  _TRAP__STEP_OVER_FUNCTIONS=()
}
alias trap.step-trace-reset="trap_step-trace-reset"

# @description Show the list of functions for which is enabled the step trace.
# @alias trap.step-trace-list
# @example
#   $ trap.step-trace-add --step-into func1 --step-over func2 func3
#   $ trap.step-trace-list
#   step-into|func1
#   step-over|func2
#   step-over|func3
trap_step-trace-list() {
  local type item
  for type in into over; do
    declare -n ary_ref=_TRAP__STEP_${type^^}_FUNCTIONS
    for item in "${ary_ref[@]}"; do
      echo "step-$type|$item"
    done
  done
}
alias trap.step-trace-list="trap_step-trace-list"

# @description Remove the provided functions from the list of functions for which is enabled the step trace (see [trap_step-trace-add()](#trap_step-trace-add)).
# @alias trap.step-trace-remove
# @arg $@ String Function name or alias to function to remove from the step-trace enabled list. The function is removed from the `step into` or `step over` mode list depending of the closest preceding option, respectively `--step-into` or `--step-over` (step into mode is used by default if no option is specified)
# @opt --step-into Disable the step into debug trace for the following functions
# @opt --step-over Disable the step over debug trace for the following functions
# @example
#   $ trap.step-trace-add --step-over func1 func2 --step-into func3    # Add func1 and func2 to the list of step over debug traced functions, and func3 to the list of step into debug traced functions
#   $ trap.step-trace-remove --step-over func1              # Disable step trace for function func1
#   $ trap.step-trace-list
#   step-into|func3
#   step-over|func2
trap_step-trace-remove() {
  args_check-number 1 -
  local type_trace=into
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --step-over) type_trace=over ; shift ;;
      --step-into) type_trace=into ; shift ;;
      *) [[ "$type_trace" = into ]] && array.remove _TRAP__STEP_INTO_FUNCTIONS "$1" || array.remove _TRAP__STEP_OVER_FUNCTIONS "$1" ; shift 1 ;;
    esac
  done
}
alias trap.step-trace-remove="trap_step-trace-remove"

# @description Enable the step trace, as configured by [trap_step-trace-add()](#trap_step-trace-add), [trap_step-trace-remove()](#trap_step-trace-remove) or [trap_step-trace-reset()](#trap_step-trace-reset).  
#   The script will pause when reaching one of the traced functions, show a debug information and wait for user input.  
# @alias trap.step-trace-start
trap_step-trace-start() {
  declare -g _TRAP__IS_TRACE=$True
}
alias trap.step-trace-start="trap_step-trace-start"

# @description Disable the step trace.
# @alias trap.step-trace-stop
trap_step-trace-stop() {
  declare -g _TRAP__IS_TRACE=$False
}
alias trap.step-trace-stop="trap_step-trace-stop"

# @description Show error information.
# @alias trap.show-stack-trace
# @arg $1 Number[$_TRAP__EXITCODE_EXIT] Exit code: defaults to the exit code of EXIT trap handler
# @example
#   trap.add-error-handler CHECKERR trap.show-stack-trace
trap_show-stack-trace(){
  args_check-number 0 1
  [[ "$_TRAP__IS_COMMAND_TRACE_ENABLED" != $True ]] && { warn_msg --show-function  "Code trace not enabled: cannot show the stack trace" ; return ; }
  local exitcode="${1:-$_TRAP__EXITCODE_EXIT}"
  local file str alias found_source_file
  local stack_trace idx
  # prepare the stack trace description line joining the function name with line number for every level in the stack 
  for idx in "${!_TRAP__FUNCTION_STACK[@]}"; do
    stack_trace="$stack_trace ${_TRAP__FUNCTION_STACK[$idx]}[${_TRAP__LINENO_STACK[$idx]}]"
  done
  # find which file contain the last executed command (stored in $_TRAP__CURRENT_COMMAND) between the executed script and all the sourced files with module.import command
  for file in "${_MODULE__IMPORTED_MODULES[@]}"; do
    str="$( tail -n+$_TRAP__LINENO "$file" | head -n1 | sed -E 's/^[[:space:]]+//' )"
    [[ "$str" =~ ^[a-zA-Z_:?.\-]+ ]] || true
    if [[ -n "${BASH_REMATCH[0]}" ]]; then
      alias="${BASH_REMATCH[0]}"
      main.dereference-alias_ "${BASH_REMATCH[0]}"
      [[ "$__" != "$alias" ]] && str="$__${str:${#alias}}"
    fi
    [[
      "${str:0:${#_TRAP__CURRENT_COMMAND}}" = "$_TRAP__CURRENT_COMMAND" ||
      ( "${#str}" -gt 3 && "${_TRAP__CURRENT_COMMAND:0:${#str}}" = "$str" )
    ]] && { found_source_file="$file" ; break ; }
  done
  [[ -n "$found_source_file" ]] && local file_name_line=$'\n'"    File name: ${found_source_file##*/}"
  echo -e "${Yellow}### Stack Trace${Color_Off}
    Command: $_TRAP__CURRENT_COMMAND${file_name_line}
    Function: $_TRAP__CURRENT_FUNCTION
    Line number: $_TRAP__LINENO
    Stack trace:$stack_trace
    Exit code: $exitcode"
  [[ -n "$found_source_file" ]] && awk 'NR>L-4 && NR<L+4 { printf "%-5d%3s%s\n",NR,(NR==L?">>>":""),$0 }' L=$_TRAP__LINENO "$found_source_file"
}
alias trap.show-stack-trace="trap_show-stack-trace"