#!/bin/bash
#github-action genshdoc

# @file lock.sh
# @brief Provide locking functionalities
# @show-internal
shopt -s expand_aliases

module.import "main"
module.import "trap"

# @global _LOCK__RUN_DIR String Run dir path
_LOCK__RUN_DIR=/var/run/std-lib.bash
[ ! -d "$_LOCK__RUN_DIR" ] && mkdir -p "$_LOCK__RUN_DIR"

# @setting _LOCK__KILL_PROCESS_WAIT1 Number[0.1] Time to wait for the first check if successfully killed a process
[[ -v _LOCK__KILL_PROCESS_WAIT1 ]] || _LOCK__KILL_PROCESS_WAIT1=0.1
# @setting _LOCK__KILL_PROCESS_WAIT2 Number[0.5] Time to wait for the second check if successfully killed a process 
[[ -v _LOCK__KILL_PROCESS_WAIT1 ]] || _LOCK__KILL_PROCESS_WAIT1=0.5

# @description Remove lock and kill associated process if present
# @alias lock.kill
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock is removed and associated process is already terminated or successfuly killed
# @exitcode 1 Cannot kill process associated to lock
# @exitcode 2 Lock file cannot be deleted, but associated process is already terminated or successfully killed
# @example
#   lock.kill <tag>
lock_kill() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.lock
	local pid
	[[ -f "$pidfile" ]] && pid=$(<"$pidfile")
	if [[ -n "$pid" && -e "/proc/$pid" ]]; then
		main_is-windows? && local pgid="$pid" || local pgid="$(ps -o pgid= $pid | tr -d ' ')"
		kill -TERM -"$pgid" &>/dev/null
		sleep "$_LOCK__KILL_PROCESS_WAIT1"
		[[ -e "/proc/$pid" ]] && sleep "$_LOCK__KILL_PROCESS_WAIT2"
		if [[ -e "/proc/$pid" ]]; then
			kill -9 -"$pgid" &>/dev/null
			sleep "$_LOCK__KILL_PROCESS_WAIT1"
			[[ -e "/proc/$pid" ]] && sleep "$_LOCK__KILL_PROCESS_WAIT2"
			[[ -e "/proc/$pid" ]] && return 1
            rm -f "$pidfile" &>/dev/null || return 2
		fi
	else
		rm -f "$pidfile" &>/dev/null || return 2
	fi
	return 0
}
alias lock.kill="lock_kill"


# @description Release lock if current process own it
# @alias lock.release
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock successfully released
# @exitcode 1 Current process doesn't own the lock and cannot release it
# @exitcode 2 Lock file cannot be deleted
# @example
#   lock.release <tag>
lock_release() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.lock
	local pid
	[[ ! -f "$pidfile" ]] && return 0
	pid="$(<"$pidfile")"
	[[ "$$" != "$pid" ]] && return 1
	rm -f "$pidfile" &>/dev/null || return 2
}
alias lock.release="lock_release"


# @description Check if a lock is currently active, i.e. file lock is present and the associated process still running
# @alias lock.is-active?
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock is active
# @exitcode 1 Lock is expired (file lock not present or associated process already terminated)
# @example
#   lock.is-active? <tag>
lock_is-active?() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.lock
	[[ -f "$pidfile" && -e "/proc/$(<"$pidfile")" ]] && return 0 || return 1
}
alias lock.is-active?="lock_is-active?"


# @description Check if the current process is owning the provided lock
# @alias lock.is-mine?
# @arg $1 String[Caller script name] Lock name
# @exitcodes $True (0) if lock is present and owned by the current process
# @example
#   lock.is-active? <tag>
lock_is-mine?() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.lock
	[[ -f "$pidfile" && "$(<"$pidfile")" = "$$" ]] && return 0 || return 1
}
alias lock.is-mine?="lock_is-mine?"


# @description List of locks owned by the current process of by the process with the provided pid
# @alias lock.list_
# @arg $1 Number[PID of current process $$] Pid of the process for which determine the list of locks owned by it: if empty, all locks are returned, regardless of owner
# @return Array of lock names owned by the specified process
# @example
#   lock.is-active? <tag>
lock_list_() {
	declare -ga __a=()
	declare -a ary=( "$_LOCK__RUN_DIR"/*.lock )
	[[ "$#" = 1 && "${ary[0]}" =~ \* ]] && return
	local cur_pid="${1-$$}" lock
	for lock in "${ary[@]}"; do
		[[ -z "$cur_pid" || "$(<"$lock")" = "$cur_pid" ]] && __a+=( "${lock%.lock}" ) || true
	done
}
alias lock.list_="lock_list_"

# @description Try to obtain a lock.
#  If the lock 
# @alias lock.new
# @arg $1 String[Caller script name] Lock name
# @arg $2 String[0] If lock is busy, wait $2 amount of time: can be -1 (wait forever), 0 (don't wait) or a time format as described here (**needed link**)
# @arg $3 String[-1] If lock is busy, release the lock terminating the process owning it if it the lock is expired, i.e. if $3 amount of time is passed since the creation of the lock: can be -1 (the lock never expire), 0 (the lock expire immediately) or a time format as described here (**needed link**)
# @exitcode 0 Got the lock
# @exitcode 1 Lock is busy and is not expired
# @exitcode 2 Lock is expired but was not possible to terminate the process owning it
# @exitcode 3 Cannot obtain the lock for other reasons
# @example
#   lock.new <tag>
lock_new() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	[[ -z "$2" ]] && local wait=0 || { datetime.interval-to-sec_ "$2" ; local wait="$__" ; }
	[[ -z "$3" ]] && local expiration_time=-1 || { datetime.interval-to-sec_ "$3" ; local expiration_time="$__" ; }
	
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.lock
	local cur_pid=$$
	local msg_write_file_error="Error: cannot write to file \"$pidfile\"" exitcode_write_file_error=3
	
	trap.add-handler "LOCK_${lock_name}_RELEASE" "lock_release '$lock_name'" EXIT
	[[ -f "$pidfile" ]] || echo "$cur_pid" >"$pidfile"
	[[ "$?" != 0 ]] && { echo "$msg_write_file_error" ; return $exitcode_write_file_error ; }
	local lock_pid=$(<"$pidfile")
	# if current process already own the lock, return 0
	[[ "$lock_pid" = "$cur_pid" ]] && return 0
	# if process owning the lock is still running...
	if [[ -e "/proc/$lock_pid" ]]; then
		local start_time="$(date +%s)"
		local now_time="$start_time"
		# wait until the lock is released
		while (( $wait == -1 || $now_time-$start_time <= $wait )); do
			sleep 0.5
			# the lock is released or the process owning it terminates
			if [[ ! -e "/proc/$lock_pid" || ! -f "$pidfile" ]]; then
				# obtain the lock by writing to $pidfile
				echo "$cur_pid" >"$pidfile" || { echo "$msg_write_file_error" ; return $exitcode_write_file_error ; }
				return 0
			fi
			now_time="$(date +%s)"
		done
		local lock_creation_time=$(stat --format=%Y "$pidfile")
		# the lock is expired: kill the process owning it
		if (( $expiration_time > -1 && $now_time-$lock_creation_time >= $expiration_time )); then
			while : ; do
				main_is-windows? && local pgid="$lock_pid" || local pgid="$(ps -o pgid= $lock_pid | tr -d ' ')"
				# try to kill the process owning the lock
				kill -TERM -"$pgid" &>/dev/null
				sleep "$_LOCK__KILL_PROCESS_WAIT1"
				[[ ! -e "/proc/$lock_pid" ]] && break
				sleep "$_LOCK__KILL_PROCESS_WAIT2"
				[[ ! -e "/proc/$lock_pid" ]] && break
				kill -9 -"$pgid" &>/dev/null
				sleep "$_LOCK__KILL_PROCESS_WAIT1"
				[[ ! -e "/proc/$lock_pid" ]] && break
				sleep "$_LOCK__KILL_PROCESS_WAIT2"
				[[ ! -e "/proc/$lock_pid" ]] && break
				# fail to kill the process owning the expired lock
				return 2
			done
			echo "$cur_pid" >"$pidfile" || { echo "$msg_write_file_error" ; return $exitcode_write_file_error ; }
			return 0
		else
			# the lock is busy and is not expired
			return 1
		fi
	# the process owning the lock is already terminated
	else
		# obtain the lock by writing to $pidfile
		echo "$cur_pid" >"$pidfile" || { echo "$msg_write_file_error" ; return $exitcode_write_file_error ; }
		return 0
	fi
}
alias lock.new="lock_new"
