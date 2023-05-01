#!/bin/bash
#github-action genshdoc

# if already sourced, return
[[ -v _MAIN__LOADED ]] && return || _MAIN__LOADED=True
declare -ga _MAIN__CLASSES=(main shopt process env fd timer flag msg)

# @file main.sh
# @brief Generic bash library functions for managing shell options (`shopt`), timers, processes and file descriptors.
# @description Contains common usage functions, such as some process, shopt, file descriptor and timer management.  
#   It contains the following classes:
#   * main
#   * shopt
#   * process
#   * env
#   * fd
#   * var
#   * timer
#   * flag
#   
#   Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))
# @show-internal
shopt -s expand_aliases

module.import "args"


############
#
# GLOBALS
#

# @global-header _SETTINGS__HASH - Associative array used to store boolean values
declare -gA _SETTINGS__HASH

# @global _SETTINGS__HASH[SOURCED] Bool Is current file sourced? This flag is automatically set when the module is loaded
# @global _SETTINGS__HASH[PIPED] Bool Is current file piped to another command? This flag is automatically set when the module is loaded
# @global _SETTINGS__HASH[INTERACTIVE] Bool Is the current process running in an interactive shell? This flag is automatically set when the module is loaded
# @global _SETTINGS__HASH[CHROOTED] Bool Is current process chrooted? This flag is set when calling `main.is-chroot()`
# @global _SETTINGS__HASH[WINDOWS] Bool Is current O.S. Windows? This flag is set when calling `main.is-windows()`

# @global-header Boolean Values
# @global True 0
True=0
# @global False 1
False=1

# @global-header Others
# @global _MAIN__RAW_SCRIPTNAME String Calling script path, raw and not normalized: as seen by the shell through BASH_SOURCE variable
# @global _MAIN__SCRIPTPATH String Calling script path after any possible link resolution
# @global _MAIN__SCRIPTNAME String Calling script real name (after any possible link resolution)
# @global _MAIN__SCRIPTDIR String Absolute path where reside the calling script, after any possible link resolution
# @global _MAIN__GIT_PATH String Root path of Git for Windows environment: it's set when calling `main.is-windows()`


############
#
# SETTINGS
#

# @setting _MAIN__KILL_PROCESS_WAIT_INTERVAL Number[0.1] Seconds to wait between checks to test whether a process has been successfully killed
[[ -v _MAIN__KILL_PROCESS_WAIT_INTERVAL ]] || _MAIN__KILL_PROCESS_WAIT_INTERVAL=0.1


############
#
# INITIALITAZION
#

declare -gA _SETTINGS__HASH=([SOURCED]=$False)
[ -t 1 ] && _SETTINGS__HASH[PIPED]=$False || _SETTINGS__HASH[PIPED]=$True
declare -gA _MAIN__TIMER=()

# test if file is sourced or executed
if [ "${BASH_SOURCE[1]}" != "${0}" ]; then
  _MAIN__RAW_SCRIPTNAME="${BASH_SOURCE[-1]}"
  _SETTINGS__HASH[SOURCED]=$True
else
  _MAIN__RAW_SCRIPTNAME="$0"
fi
[ -z "${-//*i*/}" ] && _SETTINGS__HASH[INTERACTIVE]=$True || _SETTINGS__HASH[INTERACTIVE]=$False

test -L "${_MAIN__RAW_SCRIPTNAME}" && _MAIN__SCRIPTPATH="$( readlink "${_MAIN__RAW_SCRIPTNAME}" )" || _MAIN__SCRIPTPATH="${_MAIN__RAW_SCRIPTNAME}"
_MAIN__SCRIPTNAME="${_MAIN__SCRIPTPATH##*/}"


############
#
# MAIN FUNCTIONS
#
############

# @description Dereference shell aliases: return the name of the function to which an alias point to, resolving it recursively if needed
# @alias main.dereference-alias_
# @arg $1 String Name of alias to dereference
# @return String Name of function to which provided alias point to
# @example
#   $ alias alias1="func1"
#   $ alias alias2="alias1"
#   $ main.dereference-alias_ alias2
#   # return __="func1"
main_dereference-alias_() {
  args.check-number 1 || return $?
  # recursively expand alias, dropping arguments
  # output == input if no alias matches
  local function_name="$1" p
  while [[ "alias" = $(type -t -- $function_name) ]] && p=$(alias -- "$function_name" 2>&-); do
    function_name=$(sed -re "s/alias "$function_name"='(\S+).*'$/\1/" <<< "$p")
  done
  declare -g __="$function_name"
}
alias main.dereference-alias_="main_dereference-alias_"

# @description Check whether the current environment is Windows, testing if `uname -a` return a string starting with `MINGW`.  
#   Store the result $True or $False in the flag _SETTINGS__HASH[WINDOWS].
# @exitcodes Standard (0 for true, 1 for false)
# @alias main.is-windows
# @example
#   $ uname -a
#   MINGW64_NT-6.1 chiller2 2.11.2(0.329/5/3) 2018-11-10 14:38 x86_64 Msys
#   $ main.is-windows
#   # statuscode = 0
main_is-windows() {
  if [[ -z "${_SETTINGS__HASH[WINDOWS]}" ]]; then
    [[ "$( uname -a  )" =~ ^MINGW ]] && _SETTINGS__HASH[WINDOWS]=$True || _SETTINGS__HASH[WINDOWS]=$False
  fi
  return "${_SETTINGS__HASH[WINDOWS]}"
}
alias main.is-windows="main_is-windows"

# @description Check whether the script is chroot'ed, and store the value $True or $False in flag $_SETTINGS__HASH[CHROOTED].
# @alias main.is-chroot
# @exitcodes Standard (0 for true, 1 for false)
# @example
#   main.is-chroot
main_is-chroot() {
  if [ -z "${_SETTINGS__HASH[CHROOTED]}" ]; then
    [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ] && _SETTINGS__HASH[CHROOTED]=$True || _SETTINGS__HASH[CHROOTED]=$False
  fi
  return "${_SETTINGS__HASH[CHROOTED]}"
}
alias main.is-chroot="main_is-chroot"

# @description Set the current script path and the current script directory to the global variables `_MAIN__SCRIPTPATH` and `_MAIN__SCRIPTDIR`.
# @alias main.set-script-path-info
# @example
#   $ main.set-script-path-info
#   $ echo _MAIN__SCRIPTPATH=$_MAIN__SCRIPTPATH
#   _MAIN__SCRIPTPATH=/usr/local/src/script.sh
#   $ echo _MAIN__SCRIPTDIR=$_MAIN__SCRIPTDIR
#   _MAIN__SCRIPTDIR=/usr/local/src
main_set-script-path-info() {
  _MAIN__SCRIPTPATH="$( realpath "$_MAIN__SCRIPTPATH" )"
  _MAIN__SCRIPTDIR="${_MAIN__SCRIPTPATH%/*}"
}
alias main.set-script-path-info="main_set-script-path-info"


# @description Check if the script is piped.
# @alias main.is-piped
# @exitcodes Standard (0 for true, 1 for false)
main_is-piped() { [ -t 1 ] && return 1 || return 0 ; }
alias main.is-piped="main_is-piped"


############
#
# SHOPT FUNCTIONS
#
############

# @description Backup the provided shopt options.
# @alias shopt.backup
# @arg $@ String Options to be backed up
# @example
#   $ shopt -p expand_aliases
#   shopt -s expand_aliases
#   $ shopt.backup expand_aliases extdebug
#   $ shopt -u expand_aliases
#   $ shopt -p expand_aliases
#   shopt -u expand_aliases
#   $ shopt.restore expand_aliases extdebug
#   $ shopt -p expand_aliases
#   shopt -s expand_aliases
shopt_backup() {
  args.check-number 1 - || return $?
  declare -gA _MAIN__SHOPT_BACKUP
  local opt
  for opt ; do
    shopt -p $opt &>/dev/null && _MAIN__SHOPT_BACKUP["$opt"]=$True || _MAIN__SHOPT_BACKUP["$opt"]=$False
  done
}
alias shopt.backup="shopt_backup"

# @description Restore the provided shopt options backuped up by the previously called `shopt.backup` function.
# @alias shopt.restore
# @arg $@ String Options to be restored
# @example
#   $ shopt -p expand_aliases
#   shopt -s expand_aliases
#   $ shopt.backup expand_aliases extdebug
#   $ shopt -u expand_aliases
#   $ shopt -p expand_aliases
#   shopt -u expand_aliases
#   $ shopt.restore expand_aliases extdebug
#   $ shopt -p expand_aliases
#   shopt -s expand_aliases
shopt_restore() {
  args.check-number 1 - || return $?
  [[ "$#" = 0 ]] && { echo "Error arguments in function \"${FUNCNAME[0]}\"" ; return 1 ; }
  local opt is_enabled
  for opt ; do
    shopt -p $opt &>/dev/null
    is_enabled=$?
    [[ "$is_enabled" = ${_MAIN__SHOPT_BACKUP["$opt"]} ]] && continue
    if [[ "$is_enabled" = $True ]]; then
      shopt -u "$opt" &>/dev/null
    else
      shopt -s "$opt" &>/dev/null
    fi
  done
}
alias shopt.restore="shopt_restore"


############
#
# TIMER FUNCTIONS
#
############

# @description Start a timer
# @alias timer.start
# @arg $1 String[_] Name of timer
timer_start() {
  args.check-number 0 1 || return $?
  local name="${1:-_}"
  _MAIN__TIMER[$name]="$SECONDS"
}
alias timer.start="timer_start"

# @description Return the seconds elapsed for the provided timer
# @alias timer.elapsed
# @arg $1 String[_] Name of timer
# @return Return the elapsed seconds for the timer
# @example
#   $ timer.start timer1
#   $ sleep 5
#   $ timer.elapsed timer1
#   # return __=5
timer_elapsed() {
  args.check-number 0 1 || return $?
  local name="${1:-_}"
  declare -g __=$(($SECONDS-${_MAIN__TIMER[$name]}))
}
alias timer.elapsed="timer_elapsed"


############
#
# FD FUNCTIONS
#
############

# @description Get the first file descriptor number available.
# @alias hfd.get_
# @noargs
# @return File descriptor number
fd_get_() {
  local start_fd=11
  while [ -e /proc/$$/fd/$start_fd ]; do
    (( start_fd+=1 ))
  done
  declare -g __="$start_fd"
}
alias fd.get_="fd_get_"


############
#
# PROCESS MANAGEMENT
#
############

# @description Check if a process with provided PID exists.
# @alias process.exists
# @arg $1 Number PID of the process
# @exitcodes 0 if process exists, 1 otherwise
alias process_exists="ps -p &>/dev/null"
alias process.exists="ps -p &>/dev/null"

# @description Test if process with provided PID is a child of the current process.
# @alias process.is-child
# @arg $1 Number PID of the process
# @exitcodes 0 if process is a child process, 1 otherwise
process_is-child() {
  local pid="$1"
  command_stdout_ ps -o ppid:1= --pid $pid 2>&-
  [ "$__" = "$BASHPID" ]
}
alias process.is-child="process_is-child"

# @description Kill a process and wait for the process to actually terminate.
# @alias process.kill
# @arg $1 Number PID of the process to kill
# @arg $2 String[TERM] Signal to send
# @arg $2 Number[3] Seconds to wait for the process to end: if zero, kill the process and return immediately
# @exitcodes 0 if process is successfully killed, 1 otherwise (not killed or not ended before the timeout period)
process_kill() {
  local pid="$1" signal="${2:-TERM}" wait="${3:-3}"
  process_exists "$pid" || return 0

  kill "-${signal}" "$pid" &>/dev/null
  timer_start _main__process_kill
  local elapsed_time=0
  while [ -n "$wait" -a "$elapsed_time" -lt "$wait" ]; do
    process_exists "$pid" || return 0
    sleep $_MAIN__KILL_PROCESS_WAIT_INTERVAL
    timer_elapsed _main__process_kill ; elapsed_time="$__"
  done
  process_exists "$pid" && return 1 || return 0
}
alias process.kill="process_kill"


############
#
# ENV FUNCTIONS
#
############

# @description Append the provided path to the `PATH` environment variable if not yet present.
# @alias env.PATH.append-item
# @arg $1 String Path to append
env_PATH_append-item() {
  [[ ":$PATH:" != *":$1:"* ]] && export PATH="${PATH}:$1"
}
alias env.PATH.append-item="env_PATH_append-item"

# @description Prepend the provided path to the `PATH` environment variable if not yet present.
# @alias env.PATH.prepend-item
# @arg $1 String Path to prepend
env_PATH_prepend-item() {
  [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:${PATH}"
}
alias env.PATH.prepend-item="env_PATH_prepend-item"


############
#
# FILE FUNCTIONS
#
############

# @description Create a `fifo` in shared memory (`/dev/shm`) and return his path
# @alias file.mkfifo_
# @return The path of the newly create `fifo`
file_mkfifo_() {
  declare -g __=/dev/shm/std-lib__file__${RANDOM}.fifo
  while ! mkfifo $__ &>/dev/null; do
    __=/dev/shm/std-lib__file__${RANDOM}.fifo
  done
}

############
#
# COMMAND FUNCTIONS
#
############

# @description Execute a command and return the first line of his standard output (or an empty string if no output is present).
#   It use a `fifo` and appropriate redirection to get the standard output of the command without using a subshell (see this [Stackoverflow answer](https://stackoverflow.com/a/21636953/3821238)).
# @alias command.stdout_
# @arg $@ String Command to execute
# @exitcodes The status code of the executed command
# @return The standard output of the provided command
command_stdout_() {
  file_mkfifo_ ; local __command_stdout__fifo_path="$__"
  fd_get_ ; local __command_stdout__fd="$__"
  eval "exec ${__command_stdout__fd}<> $__command_stdout__fifo_path"  # open file descriptior `__command_stdout__fd` for read-write access to the fifo
  unlink "$__command_stdout__fifo_path" # unlink the fifo, which will be actually deleted when no process is using it
  eval "\"\$@\" 1>&${__command_stdout__fd}" # exec the command and send the output to the fd `__command_stdout__fd` (which is connected to the fifo)
  local __command_stdout__ret=$?
  declare -g __
  if read -u${__command_stdout__fd} -t 0; then
    read -u${__command_stdout__fd} __ # read the output (first line only) from the fifo
  else
    __=""
  fi
  eval "exec ${__command_stdout__fd}>&-" # close the temporary fd
  return $__command_stdout__ret
}
alias command.stdout_="command_stdout_"

############
#
# VAR FUNCTIONS
#
############

# @description Execute a command and store the first line of his standard output (or an empty string if no output is present) to the provided variable name.
#   It use a `fifo` and appropriate redirection to get the standard output of the command without using a subshell (see this [Stackoverflow answer](https://stackoverflow.com/a/21636953/3821238)).
# @alias var.assign
# @arg $1 String Variable name where to store the standard output
# @arg $@ String Command to execute
# @exitcodes The status code of the executed command
var_assign() {
  declare -n __var_assign__var=$1
  file_mkfifo_ ; local __var_assign__fifo_path="$__"
  fd_get_ ; local __var_assign__fd="$__"
  eval "exec ${__var_assign__fd}<> $__var_assign__fifo_path" # open file descriptior `__command_stdout__fd` for read-write access to the fifo
  unlink "$__var_assign__fifo_path" # unlink the fifo, which will be actually deleted when no process is using it
  shift
  eval "\"\$@\" 1>&${__var_assign__fd}" # exec the command and send the output to the fd `__command_stdout__fd` (which is connected to the fifo)
  local __var_assign__ret=$?
  if read -u${__var_assign__fd} -t 0; then
    read -u${__var_assign__fd} __var_assign__var
  else
    __var_assign__var=""
  fi
  eval "exec ${__var_assign__fd}>&-"
  return $__var_assign__ret
}
alias var.assign="var_assign"

# @description Check if the provided variable is defined (regardless if it contains a null string or not)
# @alias var.is-set
# @arg $1 String Variable name to check
# @exitcodes Standard (0 for true, 1 for false)
var_is-set() {
  eval "[ \${$1+x} ]"
}
alias var.is-set="var_is-set"

# @description Return the first not null value of the provided variables
# @alias var.first-not-null_
# @alias var.coalesce_
# @arg $@ String Variable names whose values needs to be checked: the first not null value will be returned
# @return The first not null value of the provided variables
# @exitcodes 0 if a not null value is found, 1 otherwise
var_first-not-null_() {
  declare -g __=""
  while [[ $# -gt 0 ]]; do
    [ -n "$1" ] && { __="$1" ; return 0 ; }
    shift
  done
  return 1
}
alias var.first-not-null_="var_first-not-null_"
alias var.coalesce_="var_first-not-null_"

# @description Return the value of the first defined variable (even if it's a null value)
# @alias var.first-defined_
# @arg $@ String Variable names whose values needs to be checked: the first not null value will be returned
# @return The first not null value of the provided variables
# @exitcodes 0 if a defined variable is found, 1 otherwise
var_first-defined_() {
  declare -g __=""
  while [[ $# -gt 0 ]]; do
    eval "[ \${$1+x} ]" && { __="$1" ; return 0 ; }
    shift
  done
  return 1
}
alias var.first-defined_="var_first-defined_"

############
#
# SETTINGS FUNCTIONS
#
############

# @description Return true if the provided setting is enabled
# @alias settings.is-enabled
# @arg $1 String The setting name to check
# @exitcodes Standard (0 for true, 1 for false)
# @example
#   $ settings.is-enabled TEST
#   # exitcode=1
#   $ settings.enable TEST
#   $ settings.is-enabled TEST && echo ENABLED
#   ENABLED
settings_is-enabled() { [ "${_SETTINGS__HASH[$1]}" = $True ] ; }
alias settings.is-enabled="settings_is-enabled"

# @description Return true if the provided setting is disabled.
#   The function only test if the setting has been explicitly disabled: testing a setting not being defined will return false.
# @alias settings.is-disabled
# @arg $1 String The setting name to check
# @exitcodes Standard (0 for true, 1 for false)
# @example
#   $ settings.is-disabled TEST
#   # exitcode=1
#   $ settings.enable TEST
#   $ settings.is-disabled TEST
#   # exitcode=1
#   $ settings.disable TEST
#   $ settings.is-disabled TEST && echo DISABLED
#   DISABLED
settings_is-disabled() { [ "${_SETTINGS__HASH[$1]}" = $False ] ; }
alias settings.is-disabled="settings_is-disabled"

# @description Enable the provided setting.
# @alias settings.enable
# @arg $1 String The setting to enable
# @example
#   $ settings.is-enabled TEST
#   # exitcode=1
#   $ settings.enable TEST
#   $ settings.is-enabled TEST && echo ENABLED
#   ENABLED
settings_enable() { _SETTINGS__HASH[$1]=$True ; }
alias settings.enable="settings_enable"

# @description Disable the provided setting.
# @alias settings.disable
# @arg $1 String The setting to disable
# @example
#   $ settings.is-disabled TEST
#   # exitcode=1
#   $ settings.disable TEST
#   $ settings.is-disabled TEST && echo DISABLED
#   DISABLED
settings_disable() { _SETTINGS__HASH[$1]=$False ; }
alias settings.disable="settings_disable"

# @description Set the value of a setting.
# @alias settings.set
# @arg $1 String The setting to set
# @arg $2 String The value to set
# @example
#   $ settings.set COLOR Red
#   $ settings.get_ COLOR
#   # return __="Red"
settings_set() { _SETTINGS__HASH[$1]="$2" ; }
alias settings.set="settings_set"

# @description Get the value of a setting.
# @alias settings.get_
# @arg $1 String The setting from which to retrieve the value
# @example
#   $ settings.set COLOR Red
#   $ settings.get_ COLOR
#   # return __="Red"
settings_get_() { declare -g __="${_SETTINGS__HASH[$1]}" ; }
alias settings.get_="settings_get_"
