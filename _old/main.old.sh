return
===
===
[[ "${_MAIN__CMD_LOGFILE+x}" ]] || _MAIN__CMD_LOGFILE=/var/log
[ ${__vs_cmds_logfile+x} ] || __vs_cmds_logfile=/var/log/vargiuscuola/${_MAIN__SCRIPTDIR}_cmds.log



####
#
# flag, optarg e opzioni multiple
#

# un paio di funzione in prestito da parseargs
parseargs_is_opt() { [ "${__OPTS[$1]}" = 1 ] ; }
parseargs_is_optarg() { [ "${__OPTARGS[$1]}" = 1 ] ; }
parseargs_is_disabled_optarg() { [ "${__OPTARGS[$1]}" = 0 ] ; }
parseargs_get_optarg() { echo "${__OPTARGS[$1]}" ; }
parseargs_get_optarg_() { declare -g __="${__OPTARGS[$1]}" ; }
parseargs_set_optarg() { __OPTARGS[$1]="$2" ; }
parseargs_enable_optarg() { __OPTARGS[$1]=1 ; }
parseargs_disable_optarg() { __OPTARGS[$1]=0 ; }
parseargs_is_default() { [ "${__DEFAULTS[$1]}" = 1 ] ; }

# funzioni per gestire variabili di tipo flag (si/no)
function is_flag() { [ "${_MAIN__FLAGS[$1]}" = 1 ] ; }
function is_flag_disabled() { [ "${_MAIN__FLAGS[$1]}" = 0 ] ; }
function enable_flag() { _MAIN__FLAGS[$1]=1 ; }
function disable_flag() { _MAIN__FLAGS[$1]=0 ; }
function set_flag() { [[ "$2" = on || "$2" = yes || "$2" = 1 ]] && _MAIN__FLAGS[$1]=1 || _MAIN__FLAGS[$1]=0 ; }
function get_flag_() { declare -g __="${_MAIN__FLAGS[$1]}" ; }

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
# varie
#

define(){ IFS='\n' read -r -d '' ${1} || true; }
is_piped() { [ -t 1 ] && return 1 || return 0 ; }
is_piped && enable_flag IS_PIPED || disable_flag IS_PIPED

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
#  return code: valore della scelta
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

