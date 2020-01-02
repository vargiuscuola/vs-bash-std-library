#!/bin/bash

# $_ != $0
[[ "$1" != "-f" && "$1" != "-x" && "$IS_LOADED_FUNCTIONS_COMMON" = 1 ]] && return
IS_LOADED_FUNCTIONS_COMMON=1
RUN_DIR=/var/run/vargiuscuola
[ ! -d "$RUN_DIR" ] && mkdir -p "$RUN_DIR"
declare -A __FLAGS
# verifica se e' una sessione chroot
[ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ] && __FLAGS[CHROOTED]=1
# verifica se lo script e sourced
if [[ "${BASH_SOURCE[1]}" != "${0}" ]]; then
	RAW_SCRIPTNAME="${BASH_SOURCE[1]}"
	__FLAGS[SOURCED]=1
else
	RAW_SCRIPTNAME="$0"
fi
if [ ! ${SCRIPTNAME+x} ]; then
	SCRIPTPATH="$( test -L "${RAW_SCRIPTNAME}" && readlink "${RAW_SCRIPTNAME}" || echo "${RAW_SCRIPTNAME}" )"
	SCRIPTPATH="$( realpath "$SCRIPTPATH" )"
	SCRIPTNAME="$(basename "$SCRIPTPATH")"
	SCRIPTDIR="$( dirname "$SCRIPTPATH")"
fi
[ ${__vs_cmds_logfile+x} ] || __vs_cmds_logfile=/var/log/vargiuscuola/${SCRIPTNAME}_cmds.log

############
#
# COSTANTI

function get_ext_color() { local color ; [ -n "$1" ] && color="38;5;$1" ; [ -n "$2" ] && str_concat color "48;5;$1" ';' ; echo -ne "\e[${color}m"; }
# Reset
Color_Off='\e[0m'
# Regular Colors
Black='\e[0;30m' Red='\e[0;31m' Green='\e[0;32m' Yellow='\e[0;33m' Blue='\e[0;34m' Purple='\e[0;35m' Cyan='\e[0;36m' White='\e[0;37m' Orange="$( get_ext_color 208 )"
# Bold
BBlack='\e[1;30m' BRed='\e[1;31m' BGreen='\e[1;32m' BYellow='\e[1;33m' BBlue='\e[1;34m' BPurple='\e[1;35m' BCyan='\e[1;36m' BWhite='\e[1;37m'
# Underline
UBlack='\e[4;30m' URed='\e[4;31m' UGreen='\e[4;32m' UYellow='\e[4;33m' UBlue='\e[4;34m' UPurple='\e[4;35m' UCyan='\e[4;36m' UWhite='\e[4;37m'
# Background
On_Black='\e[40m' On_Red='\e[41m' On_Green='\e[42m' On_Yellow='\e[43m' On_Blue='\e[44m' On_Purple='\e[45m' On_Cyan='\e[46m' On_White='\e[47m'
# High Intensty
IBlack='\e[0;90m' IRed='\e[0;91m' IGreen='\e[0;92m' IYellow='\e[0;93m' IBlue='\e[0;94m' IPurple='\e[0;95m' ICyan='\e[0;96m' IWhite='\e[0;97m'
# Bold High Intensty
BIBlack='\e[1;90m' BIRed='\e[1;91m' BIGreen='\e[1;92m' BIYellow='\e[1;93m' BIBlue='\e[1;94m' BIPurple='\e[1;95m' BICyan='\e[1;96m' BIWhite='\e[1;97m'
# High Intensty backgrounds
On_IBlack='\e[0;100m' On_IRed='\e[0;101m' On_IGreen='\e[0;102m' On_IYellow='\e[0;103m' On_IBlue='\e[0;104m' On_IPurple='\e[10;95m' On_ICyan='\e[0;106m' On_IWhite='\e[0;107m'


#############################################
#############################################
##
## FUNZIONI
##
#############################################
#############################################

####
#
# flag, optarg e opzioni multiple
#

# un paio di funzione in prestito da parseargs
function parseargs_is_opt() { [ "${__OPTS[$1]}" = 1 ] ; }
function parseargs_is_optarg() { [ "${__OPTARGS[$1]}" = 1 ] ; }
function parseargs_is_disabled_optarg() { [ "${__OPTARGS[$1]}" = 0 ] ; }
function parseargs_get_optarg() { echo "${__OPTARGS[$1]}" ; }
function parseargs_get_optarg_() { declare -g __="${__OPTARGS[$1]}" ; }
function parseargs_set_optarg() { __OPTARGS[$1]="$2" ; }
function parseargs_enable_optarg() { __OPTARGS[$1]=1 ; }
function parseargs_disable_optarg() { __OPTARGS[$1]=0 ; }
function parseargs_is_default() { [ "${__DEFAULTS[$1]}" = 1 ] ; }

# funzioni per gestire variabili di tipo flag (si/no)
function is_flag() { [ "${__FLAGS[$1]}" = 1 ] ; }
function is_flag_disabled() { [ "${__FLAGS[$1]}" = 0 ] ; }
function enable_flag() { __FLAGS[$1]=1 ; }
function disable_flag() { __FLAGS[$1]=0 ; }
function set_flag() { [[ "$2" = on || "$2" = yes || "$2" = 1 ]] && __FLAGS[$1]=1 || __FLAGS[$1]=0 ; }
function get_flag_() { declare -g __="${__FLAGS[$1]}" ; }

# opzioni multiple di parseargs
function parseargs_get_multopt() { local ary_string="$(declare -p __OPTS_$1 2>/dev/null)" ; eval "declare -ga $2$( [ -n "$ary_string" ] && echo "=${ary_string#*=}" )" ; }
function parseargs_set_multopt() { local aryname=__OPTS_$1 ; eval "$aryname=(\""'$2'"\")" ; }
function parseargs_add_multopt() { local aryname=__OPTS_$1 ; eval "$aryname+=(\""'$2'"\")" ; }


####
#
# messaggi di output
#

prefix_date() {
	local _common__format
	[ -n "$1" ] && _common__format="$1" || _common__format="%d/%m/%Y %H:%M:%S"
	awk "{ print strftime(\"$_common__format\"), \$0; fflush() }"
}

printf_color() {
	[[ "${__OPTS[COLOR]}" = 1  || "${__FLAGS[IS_PIPED]}" != 1 ]] && printf "$@" || ( printf "$@" | sed -r "s/\x1B\[([0-9]{1,3};){0,2}[0-9]{0,3}[mGK]//g" )
}

show_msg() {
	local type="$1" && shift
	local add_arg="" color exit_code is_stderr is_tty is_indent
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--) shift ; break ;;
			--exit) exit_code="$2" ; shift 2 ;;
			-n) shift ; str_concat add_arg "-n" ;;
			-e) shift ; str_concat add_arg "-e" ;;
			--color) color="$2" ; shift 2 ;;
			--stderr) is_stderr=1 ; shift ;;
			--stdout) is_stderr=0 ; shift ;;
			--tty) is_tty=1 ; shift ;;
			--indent) is_indent=1 ; shift ;;
			*) break ;;
		esac
	done
	[[ "$type" = ERROR && -z "$is_stderr" ]] && is_stderr=1
	if [ -z "$color" ]; then
		declare -A color_table=([ERROR]="$Red" [OK]="$BGreen" [WARNING]="$Yellow" [INFO]="$Cyan" [INPUT]="$Yellow")
		color="${color_table[$type]}"
	fi
	if [[ "$is_tty" = 1 || "$is_stderr" = 1 ]]; then
		get_fd_ ; local fd_stdout=$__
		if [ "$is_tty" = 1 ]; then
			eval "exec $fd_stdout>&1 >/dev/tty"
		elif [ "$is_stderr" = 1 ]; then
			eval "exec $fd_stdout>&1 >&2"
		fi
	fi
	[ "$is_indent" = 1 ] && print_indent
	( parseargs_is_optarg COLOR || [ -t 1 ] ) && { echo -ne "$color"[$type]"$Color_Off " ; echo $add_arg "$@" ; } || echo $add_arg [$type] "$@"
	[[ "$is_stderr" = 1 || "$is_tty" = 1 ]] && eval "exec >&$fd_stdout $fd_stdout>&-" || true
	[ -n "$exit_code" ] && exit "$exit_code" || return 0
}
error_msg() { show_msg ERROR --color $BRed "$@" ; } # ERROR in rosso
ok_msg() { show_msg OK --color $Green "$@" ; } # OK in verde
warn_msg() { show_msg WARNING --color $Yellow "$@" ; } # WARNING in giallo
info_msg() { show_msg INFO --color $Cyan "$@" ; } # INFO in ciano
input_msg() { show_msg INPUT --tty --color $( get_ext_color 141 ) -n "$@" ; } # INPUT in viola
test_msg() { show_msg TEST --color $Orange "$@" ; } # TEST in arancione
debug_msg() { show_msg DEBUG --color $Orange "$@" ; } # DEBUG in arancione


####
#
# avvio comandi multipli
#

# run_cmd_list
run_cmd_list() {
	local _common__cmd _common__log_to _common__is_append=0 _common__ignore_status=0 _common__is_silent=0 _common__ret _common__args=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--log-to) [ "$2" = - ] && _common__log_to="$__vs_cmds_logfile" || _common__log_to="$2" ; _common__args+=( "--log-to" "$_common__log_to" "--append-log" ) ; shift 2 ;;
			--append-log) _common__is_append=1 ; shift ;;
			--ignore-status) _common__ignore_status=1 ; _common__args+=( "--ignore-status" ) ; shift ;;
			--silent) _common__is_silent=1 ; _common__args+=( "--silent" ) ; shift ;;
			--) break ;;
			*) break ;;
		esac
	done
	[[ -n "$_common__log_to" && "$_common__is_append" = 0 ]] && echo -n >"$_common__log_to"
	local _common__title="$1" && shift
	local _common__cmds=("$@")
	
	parseargs_is_optarg VERBOSE && [ -n "$_common__title" ] && info_msg "### $_common__title:"
	parseargs_is_optarg TEST && ! parseargs_is_optarg VERBOSE && return
	for _common__cmd in "${_common__cmds[@]}"; do
		[ -z "$_common__cmd" ] && continue
		if [ "${__OPTARGS[TEST]}" = 1 ]; then
			echo $_common__cmd
		else
			run_cmd "${_common__args[@]}" -- $_common__cmd
			_common__ret="$?"
			[[ "$_common__ignore_status" = 0 && "$_common__ret" != 0 ]] && { parseargs_is_optarg VERBOSE && [ -n "$_common__title" ] && info_msg "---" ; return "$_common__ret" ; }
		fi
	done
	parseargs_is_optarg VERBOSE && [ -n "$_common__title" ] && info_msg "---" || true
}

# run_cmd
run_cmd() {
	local _common__log_to _common__is_append=0 _common__ignore_status=0 _common__is_silent=0 _common__no_newline=0 _common__ret _common__echo_args
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--log-to) [ "$2" = - ] && _common__log_to="$__vs_cmds_logfile" || _common__log_to="$2" ; shift 2 ;;
			--append-log) _common__is_append=1 ; shift ;;
			--ignore-status) _common__ignore_status=1 ; shift ;;
			--silent) _common__is_silent=1 ; shift ;;
			-n) _common__no_newline=1 ; _common__echo_args=-n ; shift ;;
			-*) shift ; break ;;
			*) break ;;
		esac
	done
	if parseargs_is_optarg VERBOSE; then
		[ "${FUNCNAME[1]}" = run_cmd_list ] && echo $_common__echo_args "Cmd: $@ " || info_msg $_common__echo_args "Cmd: $@ "
	fi
	if ! parseargs_is_optarg DEBUG; then
		if [ -n "$_common__log_to" ]; then
			get_fd_ ; local _common__fd_stdout=$__
			get_fd_ ; local _common__fd_stderr=$__
			if [ "$_common__is_append" = 1 ]; then
				eval "exec $_common__fd_stdout>&1 $_common__fd_stderr>&2 >>\"$_common__log_to\" 2>&1"
				echo "## Run command: $@"
			else
				eval "exec $_common__fd_stdout>&1 $_common__fd_stderr>&2 &>\"$_common__log_to\""
			fi
		fi
		eval "$@"
		_common__ret="$?"
		if [ -n "$_common__log_to" ]; then
			[[ "$_common__is_append" = 1 && "$_common__ret" != 0 && "$_common__ignore_status" = 0 ]] && echo "#- Ret status: $_common__ret [$@]"
			eval "exec >&$_common__fd_stdout 2>&$_common__fd_stderr $_common__fd_stdout>&- $_common__fd_stderr>&-"
		fi
		if [ "$_common__ignore_status" = 1 ]; then
			return 0
		else
			[[ "$_common__ret" != 0 && "$_common__is_silent" = 0 ]] && error_msg $_common__echo_args "Errore nell'esecuzione del seguente comando: $@"
			return $_common__ret
		fi
	fi
}


####
#
# gestione identazione
#
__INDENT_N=0
__INDENT_NCH=4
add_ident() { add_indent "$@" ; }
sub_ident() { sub_indent "$@" ; }
set_ident() { set_indent "$@" ; }

add_indent() { (( __INDENT_N += 1 )) ; }
sub_indent() { [ "$__INDENT_N" -gt 0 ] && (( __INDENT_N -= 1 )) ; }
set_indent() { __INDENT_N=$1 ; }
set_indent_nchars() { __INDENT_NCH=$1 ; }
print_indent() {
	local i indent_str
	for ((i=1 ; i<=$__INDENT_NCH; i++)); do
		indent_str="${indent_str} "
	done
	for ((i=1 ; i<=$__INDENT_N; i++)); do
		echo -n "$indent_str"
	done
}


####
#
# trap handler
#

# add_trap_handler($func, $exit_code, $signal, [...])
# aggiunge come hook ai segnali specificati la funzione $func e con exit code $exit_code
add_trap_handler() {
    local func="${1//\"/\\\"}" ; shift
	local exit_code="$1" ; shift
    local sig
	local idx
	for sig ; do
		eval "idx=\${#SIGNALS_HOOKS_$sig[@]}"
		declare -g "SIGNALS_HOOKS_$sig[$idx]"="$func"
		trap "trap_handler_helper $sig $exit_code" $sig
    done
}

# trap_handler_helper($sig, $exit_code)
# funzione che gestisce i segnali
trap_handler_helper() {
	local sig=$1
    local exit_code=$2
	local cur_func
	
	if declare -p SIGNALS_HOOKS_$sig 2>/dev/null | grep -q 'declare \-a'; then
		local idx
		local length=$(eval "echo \${#SIGNALS_HOOKS_$sig[@]}")
		for (( idx=0; idx<$length; idx++ )); do
			cur_func="$(eval "echo \"\${SIGNALS_HOOKS_$sig[$idx]}\"")"
			eval "$cur_func"
		done
	fi
	if [ "$sig" = "INT" ]; then
		trap - INT
		kill -INT $$
	fi
	[[ ( -n "$exit_code" && "$exit_code" != "-" ) && "$sig" != "EXIT" ]] && exit $exit_code || return 0
}


####
#
# lock
#

# kill_lock($lock)
# termina il processo che ha richiesto il lock $lock 
kill_lock() {
	local file_pid
	local pidfile="$RUN_DIR"/${1%.sh}.pid
	[[ -f "$pidfile" ]] && file_pid=$(<"$pidfile")
	if [[ -n "$file_pid" ]] && ps --pid "$file_pid" &>/dev/null; then
		local pgid=$(ps -o pgid= $file_pid | tr -d ' ')
		kill -TERM -"$pgid" &>/dev/null
		sleep 1.5
		if ps --pid "$file_pid" &>/dev/null; then
			kill -9 -"$pgid" &>/dev/null
			sleep 2
			ps --pid "$file_pid" &>/dev/null && return 1
		fi
	fi
}

# info_lock $program
# ritorna 0 se esiste il lock ed il programma e' in esecuzione
info_lock() {
	local pidfile="$RUN_DIR"/${1%.sh}.pid
	if [ -f "$pidfile" ] && ps --pid "$(<"$pidfile")" &>/dev/null; then
		 return 0
	else
		return 1
	fi
}

# get_lock $process_timeout $process_timeout2 $lock_name
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
get_lock() {
	local LOCKNAME=${3:-$(basename -- ${0%.sh})}
	local PIDFILE="$RUN_DIR"/$LOCKNAME.pid
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

# release_lock
# rilascia il lock
release_lock() {
	local lock_name="$1"
	[ -z "$lock_name" ] && lock_name=$(basename ${0%.sh})
	local PIDFILE="$RUN_DIR"/$lock_name.pid
	local PROCESS_PID=$$
	local FILE_PID
	test -f "$PIDFILE" && FILE_PID="$(<"$PIDFILE")" || true
	[ "$PROCESS_PID" = "$FILE_PID" ] && rm -f "$PIDFILE"
}


####
#
# array
#

# split_string
split_string() {
	local str="$1" aryname="$2" ch="${3- }"
	local IFS="$ch"
	readarray -t $aryname <<<"${str//$ch/
}"
}

# split_string_to_h
split_string_to_h() {
	local hname="$1" hkeys="$2" str="$3" ch="${4- }"
	local item
	set -- $hkeys
	unset $hname
	declare -gA $hname
	while read item; do
		[ -z "$1" ] && break
		#declare -gA $hname+=([$1]="$item")
		eval "$hname[$1]=\"\$item\""
		shift
	done <<<"${str//$ch/
}"
}

# join_array
join_array() {
	local aryname="$1[*]" varname="$2" sep="${3- }"
	local IFS="" ; local res="${!aryname/#/$sep}"
	eval "$varname=\"\${res:\${#sep}}\""
}

# array_index_of($array_name, $search_val)
# ritorna l'indice di $search_val nell'array $array_name
array_index_of_() {
	local array_name=$1[@] search="$2"
	local my_array=("${!array_name}") i
	for (( i = 0; i < ${#my_array[@]}; i++ )); do
		if [ "${my_array[$i]}" = "$search" ]; then
			declare -g __=$i
			return 0
		fi
	done
	declare -g __=
	return 1
}
array_index_of() { array_index_of_ "$@" ; [ "$?" = 0 ] && echo "$__" || return $? ; }

# in_array($find, $el1, ...)
# restituisce true (0) se $find si trova nella lista degli elementi successivi
in_array() {
	local e
	for e in "${@:2}"; do [ "$e" == "$1" ] && return 0; done
	return 1
}


####
#
# funzioni hash
#
merge_hash() {
	local dest="$1" hash="$2"
	local def_h1="$( declare -p $dest )" def_h2="$( declare -p $hash )"
	shopt -s extglob
	def_h1="${def_h1#*\(}" ; def_h1="${def_h1%)*(\')}" ; def_h2="${def_h2#*\(}" ; def_h2="${def_h2%)*(\')}"
	shopt -u extglob
	eval "$dest=($def_h1 $def_h2)"
}

# copy_hash <from> <to>
# duplica un hash
copy_hash() {
	local from="$1" to="$2"
	local cmd="declare -gA $to"
	local assoc_array_string="$(declare -p $from 2>/dev/null)"
	[ -n "$assoc_array_string" ] && eval "${cmd}=${assoc_array_string#*=}" || eval "$cmd=()"
}

# search_hash_by_value_
search_hash_by_value_() {
	local hname="$1" value="$2" key
	for key in $( eval "echo \${!$hname[@]}" ); do
		varname="$hname[$key]"
		[ "${!varname}" = "$value" ] && { declare -g __="$key" ; return 0 ; }
	done
	return 1
}


####
#
# log
#

# init_log($path)
# inizializza il log $path
# Esempio: init_log /var/log/prova.log
init_log() { 
	__VS_LOG_FILE="$1"
	touch "$__VS_LOG_FILE"
}

# log($msg)
# scrive il messaggio $msg sul log con path $__VS_LOG_FILE (inizializzato da init_log)
# Esempio: log "messaggio"
log() {
	echo `date "+%Y-%m-%d %H:%M:%S"`# "$*" >>$__VS_LOG_FILE
}


####
#
# gestione variabili
#

# val_alt_if_null($val1, $val2, ...)
# restituisce il primo valore non nullo
val_alt_if_null() {
	while [[ $# -gt 0 ]]; do
		[ -n "$1" ] && { echo "$1" ; break ; }
		shift
	done
}
val_alt_if_null_() {
	while [[ $# -gt 0 ]]; do
		[ -n "$1" ] && { declare -g __="$1" ; break ; }
		shift
	done
}

# is_set($varname)
# determina se una variabile e' definita o meno (una variabile contenente una stringa nulla risultera' definita)
is_set() { eval "[ \${$1+x} ]" ; }


####
#
# gestione input da console
#

function finalize_read_keys() {
	[ -n "$__IFS" ] && IFS="$__IFS"
	[ -n "$__OLDSTTY" ] && { stty "$__OLDSTTY" ; } </dev/tty
}

function init_read_keys() {
	local char
	add_trap_handler finalize_read_keys "" EXIT
	{
		declare -g __OLDSTTY=`stty -g`
		stty -icanon -echo
		__IFS="$IFS"
		IFS=$'\0'
		while read -t 0 -N 0; do
			read -N 1 char
		done
		IFS="$__IFS"
	} </dev/tty
}

function read_key_() {
	local char ret=1
	[ -z "$__IFS" ] && __IFS="$IFS"
	IFS=$'\0'
	{
		if read -t 0 -N 0; then
			__=""
			while read -t 0 -N 0; do
				read -N 1 -r char
				__="$__$char"
			done
			ret=0
		fi
	} </dev/tty
	IFS="$__IFS"
	return $ret
}


####
#
# varie
#

define(){ IFS='\n' read -r -d '' ${1} || true; }
is_piped() { [ -t 1 ] && return 1 || return 0 ; }
is_piped && enable_flag IS_PIPED || disable_flag IS_PIPED
is_word_in_string() { [[ "$2" =~ (^| )$1( |$) ]] ; }

# consente di eseguire lo script mentre lo si edita: utile in caso di aggiornamenti git o simili che possono disturbare l'esecuzione dello script
# basta eseguire la funzione all'inizio dello script
edit_while_running_workaround() {
	if [[ ! "`dirname $0`" =~ ^/tmp/.sh-tmp ]]; then
		mkdir -p /tmp/.sh-tmp/
		DIST="/tmp/.sh-tmp/$( basename $0 )"
		install -m 700 "$0" $DIST
		exec $DIST "$@"
	else
		rm "$0"
	fi
}

# escape_ext_regexp: fa l'escape di una stringa per poter essere usata in una regexp extended di sed (o anche egrep)?
escape_ext_regexp() {
	local str="$1" esc_sep_ch="${2-\/}"

	[[ "$2" =~ \{|\$|\.|\*|\[|\\|\^|\||\] ]] && esc_sep_ch=
	<<<"$str" sed -E 's/([\{\$\.\*'"$esc_sep_ch"'\[\\^\|])/\\\1/g' | sed 's/[]]/\[]]/g'
}


# escape_sed_replace_: fa l'escape della stringa da utilizzare come replace del comando sed
escape_sed_replace_() {
	local rpl_str="$1" sep_ch="$2"
	
	[[ "$sep_ch" != / && "$sep_ch" != \& ]] && rpl_str="${rpl_str//${sep_ch//\*/\\*}/\\$sep_ch}"
	rpl_str="${rpl_str//\//\\/}"
	rpl_str="${rpl_str//&/\\&}"
	declare -g __="$rpl_str"
}

# funzione per ottenere un file descriptor non ancora utilizzato
get_fd_() {
	local start_fd=11
	while [ -e /proc/$$/fd/$start_fd ]; do
		(( start_fd+=1 ))
	done
	declare -g __="$start_fd"
}

# backup file descriptors
backup_fd() {
	local fdlist="1 2"
	if [ "$1" = --only-stdout ]; then
		fdlist="1" ; shift
	elif [ "$1" = --only-stderr ]; then
		fdlist="2" ; shift
	elif [ "$1" = --only-stdin ]; then
		fdlist="0" ; shift
	elif [ "$1" = --fd ]; then
		fdlist="$2" ; shift 2
	fi
	local varname="$1" curfd bckfd
	[ -z "$varname" ] && { error_msg "restore_fd: Non è stata specificato il nome della variabile" ; return 1 ; }
	
	for curfd in $fdlist; do
		get_fd_ ; bckfd=$__
		declare -g ${varname}_$$_$curfd=$bckfd
		eval "exec $bckfd>&$curfd"
	done
}

# restore file descriptors
restore_fd() {
	local fdlist="1 2"
	if [ "$1" = --only-stdout ]; then
		fdlist="1" ; shift
	elif [ "$1" = --only-stderr ]; then
		fdlist="2" ; shift
	elif [ "$1" = --only-stdin ]; then
		fdlist="0" ; shift
	elif [ "$1" = --fd ]; then
		fdlist="$2" ; shift 2
	fi
	local varname="$1" curfd tmp is_err=0
	[ -z "$varname" ] && { error_msg "restore_fd: Non è stata specificato il nome della variabile" ; return 1 ; }
	
	for curfd in $fdlist; do
		tmp="${varname}_$$_$curfd"
		[ -z "${!tmp}" ] && { error_msg "restore_fd: Impossibile ripristinare l'fd n. $curfd tramite variabile $tmp: risulta essere nulla" ; is_err=1 ; continue ; }
		eval "exec $curfd>&${!tmp} ${!tmp}>&-"
	done
	return "$is_err"
}

# funziona per gestire l'input
# choose "<domanda>" "<option1=val1> <option2=val2> ..." <default>
# Esempio: choose "Vuoi fare questo?" "s=0 n=1" s
#	return code: valore della scelta
choose() {
	local args_input_msg
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--) shift ; break ;;
			--indent) shift ; str_concat args_input_msg --indent ;;
			--no-newline) shift ; local no_newline=1 ;;
			--show-value) shift ; local is_show_value=1 ;;
			*) break ;;
		esac
	done	
	local msg="$1" accept=( $2 ) default="$3"
	local accept_str="$( printf '%s\n' "${accept[@]}" )" answer args cur_str cur_ans choice_str val
	
	# genera la stringa per la scelta
	for cur_str in "${accept[@]}"; do
		cur_ans="${cur_str%=*}"
		[ "$is_show_value" = 1 ] && val="(${cur_str#*=})"
		str_concat choice_str "$( [ "$cur_ans" = "$default" ] && echo -e "$Green[$cur_ans$val]$Color_Off" || echo "$cur_ans$val" )" /
	done
	
	# input
	[ "$no_newline" = 1 ] && args="-n 1"
	while true; do
		[ -n "$msg" ] && input_msg $args_input_msg "$msg $choice_str "
		read $args answer
		[[ -n "$answer" && "$no_newline" = 1 ]] && echo
		[[ -z "$answer" && -n "$default" ]] && return "$( <<<"$accept_str" grep -E "^$default=" | cut -d= -f 2 )"
		for cur_str in "${accept[@]}"; do
			cur_ans="${cur_str%=*}"
			val="${cur_str#*=}"
			[ "$answer" = "$cur_ans" ] && return "$val"
			[[ "$is_show_value" = 1 && "$answer" = "$val" ]] && return "$val"
		done
	done
}

# scrive gli argomenti passati con apici se necessario
# Esempio:
#    print_args a b "c d" => a b "c d"
args_to_str_() {
	local arg args
	for arg in "$@"; do
		[[ "$arg" =~ [[:space:]] || "$arg" = "" ]] && arg="\"$arg\""
		[ -z "$args" ] && args="$arg" || args="$args $arg"
	done
	declare -g __="$args"
}
print_args() {
	args_to_str_ "$@"
	echo "$__"
}
	
# str_concat($var, $str, [$sep=" "])
# concatena la stringa $str alla variabile $var separando l'eventuale contenuto precedente con il separatore $sep (di default " ")
str_concat() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-m|--multi-line) 
				shift
				eval "local old_val=\$'\n'\"\${!1}\"\$'\n'
old_val=\"\${old_val//\$'\n'/\${3:- }\$2\$'\n'}\"
old_val=\"\${old_val//\$'\n'\${3:- }\$2\$'\n'/\$'\n'\$2\$'\n'}\"
old_val=\"\${old_val#*\$'\n'}\" ; $1=\"\${old_val%\$'\n'}\""
				return
			;;
			*) break ;;
		esac
	done
	[ -z "${!1}" ] && eval "$1=\"\$2\"" || eval "$1=\"\${!1}\${3:- }\$2\""
}

# visualizza le parole uniche fornite
unique_words() {
	local str="$@" w
	declare -A hash
	for w in $str; do
		hash[$w]=1
	done
	echo "${!hash[@]}"
}


####
#
# debugging
#

# debug_command($cmd)
# esegue il debug del comando $cmd, riportando sullo stdout qualsiasi esecuzione del comando $cmd
# Da usare in accoppiata con register_debug
debug_command() {
	local cmd=$1 fd_stdout=$2 ; shift 2
	args_to_str_ "$@"
	eval "command echo \"debug_command# \$cmd \$__\" >&$fd_stdout"
	command $cmd "$@"
}

# register_command $cmd
register_debug() {
	declare -f "$1" &>/dev/null && { warn_msg "register_debug# Il comando $1 risulta già ridefinito" ; return 0 ; }
	get_fd_ ; local fd_stdout=$__
	eval "exec $fd_stdout>&1"
	eval "$1() {
		debug_command $1 $fd_stdout \"\$@\"
	}"
}

