#!/bin/bash
#github-action genshdoc

# if already sourced, return
[[ -v _LOCK__LOADED ]] && return || _LOCK__LOADED=True

# @file lock.sh
# @brief Provide locking functionalities.
#   Although different precautions are put into practice to avoid inconsistencies due to concurrency, some operations are not atomic so this library is not concurrency safe.
#   Specifically, the lock creation is atomic, while the deletion or release mechanism is not.  
#   More appropriate tools for locking couldn't be used because I wanted it to be cross platform, working on Git for Windows as well as in Linux.  
#   Avoid to use it if your requirements expect a solid locking mechanism.
# @show-internal
shopt -s expand_aliases

module.import "args"
module.import "main"
module.import "trap"
main_is-windows && export MSYS=winsymlinks:nativestrict    # enable symbolic links management in Git for Windows

# @global _LOCK__RUN_DIR String Run dir path
_LOCK__RUN_DIR=/var/run/std-lib.bash
[ ! -d "$_LOCK__RUN_DIR" ] && mkdir -p "$_LOCK__RUN_DIR"

# @setting _LOCK__KILL_PROCESS_WAIT Number[1] Seconds to wait for the killed process to terminate: the actual wait can double because a second signal KILL is sent if the first one TERM fail
[[ -v _LOCK__KILL_PROCESS_WAIT ]] || _LOCK__KILL_PROCESS_WAIT=1

# @description Remove lock and kill associated process if present.  
#   **This function is not concurrent safe.**
# @alias lock.kill
# @arg $1 String[Caller script name] An arbitrary lock name
# @exitcode 0 Lock is removed and process holding it is already terminated or successfuly killed
# @exitcode 1 Cannot kill the process holding to lock
# @exitcode 2 Lock file cannot be deleted, but process that held is already terminated or successfully killed
lock_kill() {
  args_check-number 0 1
  [[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
  
  local lockfile="$_LOCK__RUN_DIR/${lock_name}.lock"
  [[ ! -L "$lockfile" ]] && return 0                        # lock is not present, return
  local pid pidfile="$( readlink -f "$lockfile" 2>/dev/null )"
  [[ -n "$pidfile" && -f "$pidfile" ]] && pid=$(<"$lockfile")
  if [[ -n "$pid" && -e "/proc/$pid" ]]; then # if process holding the lock is still running...
    if ! process.kill "$lock_pid" TERM "$_LOCK__KILL_PROCESS_WAIT"; then # let's try to send TERM signal, if still running...
      process.kill "$lock_pid" KILL "$_LOCK__KILL_PROCESS_WAIT" || return 1 # try the KILL signal: if process is still running, return with error code
    fi
  fi
  # the process holding the lock is terminated (or killed by this function or already terminated before)
  [[ -n "$pidfile" ]] && rm -f "$pidfile" &>/dev/null
  rm -f "$lockfile" &>/dev/null || return 2
  return 0
}
alias lock.kill="lock_kill"


# @description Release lock if current process own it.  
#   **This function is not concurrent safe.**
# @alias lock.release
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock successfully released
# @exitcode 1 Current process doesn't own the lock and cannot release it
# @exitcode 2 Lock file cannot be deleted
lock_release() {
  args_check-number 0 1
  [[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
  
  local lockfile="$_LOCK__RUN_DIR/${lock_name}.lock"
  [[ ! -L "$lockfile" ]] && return 0
  local pidfile="$( readlink -f "$lockfile" 2>/dev/null )"
  if [[ -n "$pidfile" && -f "$pidfile" ]]; then
    local pid="$(<"$lockfile")"
    [[ "$BASHPID" != "$pid" ]] && return 1
  fi
  [[ -n "$pidfile" ]] && rm -f "$pidfile" &>/dev/null || true
  rm -f "$lockfile" &>/dev/null || return 2
}
alias lock.release="lock_release"


# @description Check if a lock is currently active, i.e. if file lock is present and the process holding it is still running.
#  If the process holding a lock is already terminated, the lock is released.
# @alias lock.is-active
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock is active
# @exitcode 1 Lock is expired (file lock not present)
# @exitcode 2 Lock has been released because the associated process has already terminated
lock_is-active() {
  args_check-number 0 1
  [[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
  
  local lockfile="$_LOCK__RUN_DIR/${lock_name}.lock"
  [[ ! -L "$lockfile" ]] && return 1
  local pidfile="$( readlink -f "$lockfile" 2>/dev/null )"
  [[ -n "$pidfile" && -f "$pidfile" && -e "/proc/$(<"$pidfile")" ]] && return 0 || {
    rm -f "$pidfile" "$lockfile" 2>/dev/null
    return 2
  }
}
alias lock.is-active="lock_is-active"


# @description All stale locks created by terminated processes are released.
# @alias lock.cleanup
# @exitcode 0 One or more locks has been released
# @exitcode 1 No locks has been released
# @return The number of locks released
lock_cleanup() {
  local lock_name n_released=0
  lock_list_ ""
  for lock_name in "${__a[@]}"; do
    lock_is-active "$lock_name"
    [ "$?" = 2 ] && ((n_released+=1))
  done
  declare -g __="$n_released"
  [ "$n_released" = 0 ] && return 1 || return 0
}
alias lock.cleanup="lock_cleanup"


# @description Check if the current process is holding the provided lock.
# @alias lock.is-mine
# @arg $1 String[Caller script name] Lock name
# @exitcodes $True (0) if lock is present and owned by the current process
lock_is-mine() {
  args_check-number 0 1
  [[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
  
  local lockfile="$_LOCK__RUN_DIR/${lock_name}.lock"
  [[ ! -f "$lockfile" ]] && return 1
  local pidfile="$( readlink -f "$lockfile" 2>/dev/null )"
  [[ -n "$pidfile" && -f "$pidfile" && "$(<"$pidfile")" = "$BASHPID" ]] && return 0 || return 1
}
alias lock.is-mine="lock_is-mine"


# @description List of locks owned by the current process of by the process with the provided pid.
# @alias lock.list_
# @arg $1 Number[PID of current process $BASHPID] Pid of the process for which determine the list of locks owned by it: if an empty argument is provided, all locks are returned regardless of owner
# @return Array of lock names owned by the specified process
lock_list_() {
  args_check-number 0 1
  declare -ga __a=()
  declare -a ary=( "$_LOCK__RUN_DIR"/*.lock )
  [[ "${ary[0]}" =~ \* ]] && return
  local cur_pid="${1-$BASHPID}" lock
  for lock in "${ary[@]}"; do
    [[ -z "$cur_pid" || ( -L "$lock" && -f "$( readlink -f "$lock" 2>/dev/null )" && "$(<"$lock")" = "$cur_pid" ) ]] &&
      { lock="${lock##*/}" ; __a+=( "${lock%.lock}" ) ; } ||
      true
  done
}
alias lock.list_="lock_list_"

# @description Try to obtain a lock.  
#   **This function is not concurrent safe.**
# @alias lock.new
# @arg $1 String[Caller script name] Lock name
# @arg $2 String[0] If lock is busy, wait $2 amount of time: can be -1 (wait forever), 0 (don't wait) or a time format as in [datetime.interval-to-sec_()](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-main.md#datetime_interval-to-sec_)
# @arg $3 String[-1] If lock is busy, release the lock terminating the process owning it if the lock is expired, i.e. if $3 amount of time is passed since the creation of the lock: can be -1 (the lock never expire), 0 (the lock expire immediately) or a time format as in [datetime.interval-to-sec_()](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-main.md#datetime_interval-to-sec_)
# @exitcode 0 Got the lock
# @exitcode 1 Lock is busy and is not expired
# @exitcode 2 Lock is expired but was not possible to terminate the process owning it
# @exitcode 3 Cannot obtain the lock for other reasons
lock_new() {
  args_check-number 0 3
  [[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
  [[ -z "$2" ]] && local wait=0 || { datetime.interval-to-sec_ "$2" ; local wait="$__" ; }
  [[ -z "$3" ]] && local expiration_time=-1 || { datetime.interval-to-sec_ "$3" ; local expiration_time="$__" ; }
  
  local cur_pid=$BASHPID
  local lockfile="$_LOCK__RUN_DIR/${lock_name}.lock" lock_pid pidfile_cur tmp
  if [[ -L "$lockfile" ]]; then            # if the lock is already present...
    pidfile_cur="$( readlink -f "$lockfile" 2>/dev/null )"
    [[ -n "$pidfile_cur" && -f "$pidfile_cur" ]] && lock_pid=$(<"$lockfile")
    [[ "$lock_pid" = "$cur_pid" ]] && return 0    #  and the current process hold it, then return successfully
  fi
  local pidfile="$(mktemp)"
  trap.add-handler "LOCK_${lock_name}_RELEASE" "lock_release '$lock_name'" EXIT
  
  echo "$cur_pid" >"$pidfile" || { error_msg "Cannot write pid to file \"$pidfile\"" ; return 3 ; }    # write pid to $pidfile, and exit with error if fail
  
  local start_time="$(date +%s)"
  local now_time="$start_time"
  # try to obtain the lock for $wait time
  while (( $wait == -1 || $now_time-$start_time <= $wait )); do
    ln -s "${pidfile}" "${lockfile}" &>/dev/null && return 0    # try to obtain the lock with the creation of a link (should be atomic operation): if successful, return
    if [[ -L "$lockfile" ]]; then
      tmp="$( readlink -f "$lockfile" 2>/dev/null )"
      if [[ -z "$lock_pid" || "$tmp" != "$pidfile_cur" ]]; then  # if current lock pid is not set or the pid file is changed, then evaluate again the lock_pid and pidfile_cur variables
        pidfile_cur="$tmp"
        [[ -n "$pidfile_cur" && -f "$pidfile_cur" ]] &&      # if pidfile exists...
          lock_pid=$(<"$lockfile") ||              #  read the pid and set the lock_pid and pidfile_cur variables
          lock_pid=                      #  otherwise reset them
      fi
      [[ ( ( -n "$lock_pid" && ! -e "/proc/$lock_pid" ) ||            # if lock is held by a terminated process
        ! -f "$pidfile_cur" ) &&
        "$pidfile_cur" = "$( readlink -f "$lockfile" 2>/dev/null )" ]] &&    # and lock file didn't change in the last few commands (to rule out concurrent operations by other processes)
        { rm -f "$pidfile_cur" ; rm -f "$lockfile" ; }              # then remove the current lock
    else
      lock_pid=
      pidfile_cur=
    fi
    sleep 0.5
    now_time="$(date +%s)"
  done
  # we waited $wait time without being able to obtain the lock
  
  [[ -z "$lock_pid" ]] && { rm -f "$pidfile" ; return 3 ; }    # we don't have the pid of the process currently holding the lock: we return with generic error code 3
  local lock_creation_time=$(stat --format=%Y "$lockfile")
  if (( $expiration_time > -1 && $now_time-$lock_creation_time >= $expiration_time )); then          # if the lock is expired, kill the process owning it
    while : ; do
      process.kill "$lock_pid" TERM "$_LOCK__KILL_PROCESS_WAIT" && break
      process.kill "$lock_pid" KILL "$_LOCK__KILL_PROCESS_WAIT" && break
      rm -f "$pidfile"                                      # if the process holding the lock is still running, we remove our pidfile
      trap.remove-handler "LOCK_${lock_name}_RELEASE" EXIT  #   remove the handler to release the lock
      return 2                                              #  and return with error code
    done
    [[ ! -L "$lockfile" || "$(<"$lockfile")" = "$lock_pid" ]] && { rm -f "$pidfile_cur" ; rm -f "$lockfile" ; } # we delete the current lock
    ln -s "${pidfile}" "${lockfile}" &>/dev/null && return 0 # and try again to obtain it
    rm -f "$pidfile"                                         # if fail, remove the pidfile
    return 3                                                 # and return with error code
  else
    return 1      # the lock is busy and is not expired
  fi
}
alias lock.new="lock_new"
