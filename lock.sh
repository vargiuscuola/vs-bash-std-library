#!/bin/bash
#github-action genshdoc

# @file lock.sh
# @brief Provide locking functionalities
# @show-internal
shopt -s expand_aliases

module.import "main"
module.import "trap"

# @environment _LOCK__RUN_DIR String Run dir path
_LOCK__RUN_DIR=/var/run/vargiuscuola
[ ! -d "$_LOCK__RUN_DIR" ] && mkdir -p "$_LOCK__RUN_DIR"

# @description Remove lock and kill associated process if present
# @example
#   lock.kill <tag>
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock is removed and associated process is already terminated or successfuly killed
# @exitcode 1 Cannot kill process associated to lock
# @exitcode 2 Lock file cannot be deleted, but associated process is already terminated or successfully killed
lock_kill() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.pid
	local pid
	[[ -f "$pidfile" ]] && pid=$(<"$pidfile")
	if [[ -n "$pid" && -e "/proc/$pid" ]]; then
		local pgid=$(ps -o pgid= $pid | tr -d ' ')
		kill -TERM -"$pgid" &>/dev/null
		[[ -e "/proc/$pid" ]] && sleep 1.5
		if [[ -e "/proc/$pid" ]]; then
			kill -9 -"$pgid" &>/dev/null
			[[ -e "/proc/$pid" ]] && sleep 2
			[[ -e "/proc/$pid" ]] && return 1
            rm -f "$pidfile" &>/dev/null
            [[ -f "$pidfile" ]] && return 2
		fi
	fi
}
alias lock.kill="lock_kill"

# @description Release lock if current process own it
# @example
#   lock.kill <tag>
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock successfully released
# @exitcode 1 Current process doesn't own the lock and cannot release it
# @exitcode 2 Lock file cannot be deleted
lock_release() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.pid
	local pid
	[[ -f "$pidfile" ]] && pid="$(<"$pidfile")"
	[[ "$$" = "$pid" ]] && rm -f "$pidfile" &>/dev/null || return 1
	[[ -f "$pidfile" ]] && return 2
}
alias lock.release="lock_release"


# @description Check if a lock is currently active, i.e. file lock is present and the associated process still running
# @example
#   lock.is-active? <tag>
# @arg $1 String[Caller script name] Lock name
# @exitcode 0 Lock is active
# @exitcode 1 Lock is expired (file lock not present or associated process already terminated)
lock_is-active?() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local pidfile="$_LOCK__RUN_DIR"/${lock_name}.pid
	[[ -f "$pidfile" && -e "/proc/$(<"$pidfile")" ]] && return 0 || return 1
}
alias lock.is-active?="lock_is-active?"

# @description Try to obtain a lock.
#  If the lock 
# @example
#   lock.new <tag>
# @arg $1 String[Caller script name] Lock name
# @arg $2 String[0] If lock is busy, wait $2 amount of time: can be -1 (wait forever), 0 (don't wait) or a time format as described here (**needed link**)
# @arg $3 String[-1] If lock is busy, release the lock terminating the process owning it if it is expired, that is if $3 amount of time is passed since the creation of the lock: can be -1 (the lock never expire), 0 (the lock expire immediately) or a time format as described here (**needed link**)
# @exitcode 0 Got the lock
# @exitcode 1 Lock is busy Failed to obtain the lock: lock is bu

# get_lock 
# return codes:
# 	0  e' stato ottenuto il lock
#	1  non e' stato ottenuto il lock
#	-1 errore sugli argomenti
#
# return codes nello standard output:
#	0 ottenuto immediatamente il lock
#	1 race condition: il processo concorrente non e' andato in timeout: si rinuncia al lock
#	2 race condition: il processo concorrente e' andato in timeout, quindi viene ucciso e si ottiene il lock
#	3 race condition: il processo concorrente e' andato in timeout, quindi si tenta di ucciderlo ma senza successo; si rinuncia al lock in quanto non ancora raggiunto il secondo timeout
#	4 race condition: il processo concorrente e' andato in timeout, quindi si tenta di ucciderlo ma senza successo, ma avendo superato il secondo timeout si ottiene comunque il lock
lock_new() {
	[[ -z "$1" ]] && local lock_name="${_MAIN__SCRIPTNAME%.sh}" || local lock_name="$1"
	local timeout="$2"
	
	local lock_name=${3:-$(basename -- ${0%.sh})}
	local PIDFILE="$_LOCK__RUN_DIR"/$lock_name.pid
	local PROCESS_TIMEOUT=$1
	local PROCESS_TIMEOUT2=${2:-0}
	local LOCK_FAIL=0
	local PROCESS_PID=$$
	local RETCODE
	local INFOCODE
	
	add_trap_handler release_lock "" EXIT
	[[ "$PROCESS_TIMEOUT" =~ .*g ]] && (( PROCESS_TIMEOUT=${PROCESS_TIMEOUT%g}*60*60*24 ))
	[[ "$PROCESS_TIMEOUT" =~ .*h ]] && (( PROCESS_TIMEOUT=${PROCESS_TIMEOUT%h}*60*60 ))
	[[ "$PROCESS_TIMEOUT" =~ .*m ]] && (( PROCESS_TIMEOUT=${PROCESS_TIMEOUT%m}*60 ))
	[[ "$PROCESS_TIMEOUT" =~ .*s ]] && (( PROCESS_TIMEOUT=${PROCESS_TIMEOUT%s} ))
	
	[[ "$PROCESS_TIMEOUT2" =~ .*g ]] && (( PROCESS_TIMEOUT2=${PROCESS_TIMEOUT2%g}*60*60*24 ))
	[[ "$PROCESS_TIMEOUT2" =~ .*h ]] && (( PROCESS_TIMEOUT2=${PROCESS_TIMEOUT2%h}*60*60 ))
	[[ "$PROCESS_TIMEOUT2" =~ .*m ]] && (( PROCESS_TIMEOUT2=${PROCESS_TIMEOUT2%m}*60 ))
	[[ "$PROCESS_TIMEOUT2" =~ .*s ]] && (( PROCESS_TIMEOUT2=${PROCESS_TIMEOUT2%s} ))
	
	mkdir "$(dirname "$PIDFILE")" &>/dev/null || true
	[ -f "$PIDFILE" ] && LOCK_FAIL=1
	if [ $LOCK_FAIL -ne 1 ]; then
		echo $PROCESS_PID >"$PIDFILE"
		sleep 0.2
	fi
	local FILE_PID=$(<"$PIDFILE")
	if [ "$PROCESS_PID" != "$FILE_PID" ]; then
		if ps --pid "$FILE_PID" &>/dev/null; then
			TIME_LASTPROCESS=$(stat --format=%Y "$PIDFILE")
			TIME_NOW=$(date +%s)
			DIFF_TIME=$(( $TIME_NOW-$TIME_LASTPROCESS ))
			PGID=$(ps -o pgid= $FILE_PID | tr -d ' ')
			if [[ -n "$PROCESS_TIMEOUT" && "$DIFF_TIME" -ge "$PROCESS_TIMEOUT" ]]; then
				kill -TERM -"$PGID" &>/dev/null
				sleep 5
				if ps --pid "$FILE_PID" &>/dev/null; then
					if [ "$DIFF_TIME" -ge "$PROCESS_TIMEOUT2" ]; then
						kill -9 -"$PGID" &>/dev/null
						INFOCODE=4
						RETCODE=0
					else
						INFOCODE=3
						RETCODE=1
					fi
				else
					INFOCODE=2
					RETCODE=0
				fi
			else
				INFOCODE=1
				RETCODE=1
			fi
		else
			INFOCODE=0
			RETCODE=0
		fi
	else
		INFOCODE=0
		RETCODE=0
	fi
	# termina la funzione impostando i codici di errore
	echo $INFOCODE
	[ "$RETCODE" = 0 -a "$PROCESS_PID" != "$FILE_PID" ] && echo $PROCESS_PID >"$PIDFILE"
	return $RETCODE
}


