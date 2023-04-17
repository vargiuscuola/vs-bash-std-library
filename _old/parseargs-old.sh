#!/bin/bash

[[ "$1" != "-f" && "$IS_LOADED_PARSEARGS" = 1 && $_ != $0 ]] && return
IS_LOADED_PARSEARGS=1

LIBDIR=/lib/vargiuscuola
. $LIBDIR/common.sh

declare -ga __CMDS=()
declare -gA __ARGS=()
declare -gA __DEFAULTS=()
declare -gA __OPTS=()
declare -gA __OPTARGS=()

##########
#
# FUNZIONI DI SUPPORTO
#
###
function parseargs_error() {
	[ "$__parseargs_is_autocomplete" = 1 ] && return 0
	
	[ -z "$1" ] && error_msg "Errore nella sintassi del comando" || error_msg "$1"
	parseargs_help --short
}

# parseargs_opt_to_real_
# params: <parametro> <flag>
# Esempio:
#	parseargs_opt_to_real_ "h|help" => "-h|--help"
#	parseargs_opt_to_real_ "compact" "?" => "--[no-]compact"
function parseargs_opt_to_real_() {
	local v="$1"
	while [[ "$v" =~ (^|$'\n'|\|)(.)(\||$'\n'|$) ]]; do
		v="${v/${BASH_REMATCH[0]}/${BASH_REMATCH[1]}-${BASH_REMATCH[2]}${BASH_REMATCH[3]}}"
	done
	while [[ "$v" =~ (^|$'\n'|\|)([^-][^|$'\n']+)(\||$'\n'|$) ]]; do
		v="${v/${BASH_REMATCH[0]}/${BASH_REMATCH[1]}--${BASH_REMATCH[2]}${BASH_REMATCH[3]}}"
	done
	if [[ "$2" = "?" ]]; then
		[[ "$v" =~ (^|$'\n'|\|)--([^|[$'\n']+)(\||$'\n'|$) ]] && v="${v/${BASH_REMATCH[0]}/${BASH_REMATCH[1]}--[no-]${BASH_REMATCH[2]}${BASH_REMATCH[3]}}"
	else
		while [[ "$v" =~ (^|$'\n'|\|)--([^|[$'\n']+\?)(\||$'\n'|$) ]]; do
			v="${v/${BASH_REMATCH[0]}/${BASH_REMATCH[1]}--[no-]${BASH_REMATCH[2]}${BASH_REMATCH[3]}}"
		done
	fi
	declare -g __="$v"
}

function parseargs_get_cmds_match_() {
	local BIFS="$IFS"
	IFS=$'/'
	declare -g __="${__CMDS[*]}"
	IFS="$BIFS"
}

function parseargs_get_avail_cmds_() {
	if [ "${#__CMDS[@]}" = 0 ]; then
		local v="${!__parseargs_cmds_config[@]}"
		v=$'\n'"${v// /$'\n'}"
		shopt -s extglob ; v="${v//$'\n'*([a-z])\/*([a-z\/])/}" ; shopt -u extglob
		v="${v#*$'\n'}"
		declare -g __="${v//$'\n'/ }"
	else
		parseargs_get_cmds_match_
		declare -g __="${__parseargs_cmds_config[$__]}"
	fi
}

function parseargs_get_cmd_argopt_() {
	[ "$1" == --exact ] && { shift ; local is_exact=1 ; }
	declare -n varname="$1"
	local var="$2"
	[ "$#" -lt 3 ] && { parseargs_get_cmds_match_ ; cmdlist="$__" ; } || cmdlist="$3"
	local is_arg_found=1 suffix keys varcache_name=__cache_$1_${var//[|\- ]/__}_${cmdlist//[\/\- ]/__}
	declare -p $varcache_name &>/dev/null && { declare -g __="${!varcache_name}" ; return 0 ; }
	declare -g $varcache_name
	declare -n varcache=$varcache_name
	
	declare -g __=""
	if [ -z "$var" ]; then
		suffix=""
		[ -z "$cmdlist" ] && cmdlist="-"
	else
		[ -z "$cmdlist" ] && suffix="$var" || suffix=".${var}"
	fi
	keys="${!varname[@]}"
	while [[ ! "$keys" =~ (^| )$cmdlist${suffix/|/\\|}( |$) ]]; do
		if [[ "$is_exact" = 1 || -z "$cmdlist" || "$cmdlist" = - ]]; then
			is_arg_found=0
			break
		elif [[ ! "$cmdlist" =~ / ]]; then
			if [ -n "$var" ]; then
				cmdlist=""
				suffix="$var"
			else
				cmdlist="-"
			fi
		else
			cmdlist="${cmdlist%/[[:alpha:]]*}"
		fi
	done
	[ "$is_arg_found" = 0 ] && { declare -g __="" ; varcache="" ; return 0 ; }
	declare -g __="${varname[$cmdlist$suffix]}"
	varcache="$__"
}

function parseargs_get_config_() {
	parseargs_get_cmd_argopt_ "__parseargs_$1_config" "${@:2}"
	#shopt -s extglob ; declare -g __="${__//%{*([^\}])\}%}" ; shopt -u extglob
	declare -g __="$( <<<"$__" perl -pe 's/%\{.*?\}%//g' )"
}

function parseargs_get_values_() {
	local str
	parseargs_get_cmd_argopt_ "__parseargs_$1_config"
	str="$( <<<"$__" perl -pe "\$M += s/^.*(\b$2[:+?]*(%\{(.*?)\}%)?)(\s|$).*$/\$3/ ; END{exit 1 unless \$M>0}" )"
	[ "$?" = 0 ] && declare -g __="${str%%%%*}" || { declare -g __="" ; return 1 ; }
}

function parseargs_get_default_() {
	local str
	parseargs_get_cmd_argopt_ "__parseargs_$1_config"
	str="$( <<<"$__" perl -pe "\$M += s/^.*(\b$2[:+?]*\b(%\{(.*?)\}%)?)(\s|$).*$/\$3/ ; END{exit 1 unless \$M>0}" )"
	if [ "$?" = 0 ]; then
		[[ "$str" =~ %% ]] && str="${str#*%%}" || str=""
		declare -g __="${str%%%%*}"
	else
		declare -g __=""
		return 1
	fi
}

function parseargs_get_matched_opt_() {
	shopt -s extglob
	local opt="${1##+(-)}" ; opt="${opt%%+(@(:|\?|\+))}"
	local opts_config="$2"
	local match_opt modifier set=1
	[ -z "$opts_config" ] && { parseargs_get_config_ opts ; opts_config="$__" ; }
	match_opt="$( <<<"$opts_config" grep -Eo "(^|[[:space:]])([^[:space:]]+\|)?($opt(\|[^[:space:]]*)?[:?+]*|${opt#no-}(\|[^[:space:]]*)?\?)([[:space:]]|$)" )"
	match_opt="${match_opt// }"
	modifier="${match_opt##*[a-z\-_]}"
	[[ "$modifier" = ? && "$opt" =~ ^no- ]] && set=0
	match_opt="${match_opt/[:?+]*/}"
	declare -g __="$match_opt@$modifier@$match_opt$modifier@$set"
	shopt -u extglob
}

##########
#
# FUNZIONI PRINCIPALI
#
###

function parseargs_help() {
	[ "$__parseargs_is_autocomplete" = 1 ] && return 0
	
	local cmds_match_str avail_cmds avail_cmd_str avail_args avail_args_str avail_opts opts_desc modifier tmp tmp2 arg var tag desc
	local header info str_help info_cmds info_args info_options arg_default arg_vals opt_vals opt_info
	local is_short=0
	while [[ $# -gt 0 ]]; do
		[ "$1" = "--short" ] && is_short=1
		shift
	done
	parseargs_get_cmds_match_
	cmds_match_str="$__"
	cmds_match_str="${cmds_match_str//\// }"
	[ -n "$cmds_match_str" ] && cmds_match_str="$cmds_match_str "
	
	# genera descrizione comandi
	parseargs_get_avail_cmds_
	avail_cmds="$__"
	if [ -n "$avail_cmds" ]; then
		avail_cmd_str="<comando> "
		parseargs_get_cmds_match_
		local cmds_match="$__"
		for var in $avail_cmds; do
			parseargs_get_cmd_argopt_ __parseargs_cmds_desc "" "$( str_concat cmds_match "$var" / ; echo "$cmds_match" )"
			str_concat info_cmds "    $( printf_color "$Yellow%-20s$Color_Off" "$var" )  $__" $'\n'
		done
		[ -n "$info_cmds" ] && info_cmds=$'\n\n'"$( printf_color "${UWhite}Comandi disponibili$Color_Off" )"$'\n'"$info_cmds"
	else
		avail_cmd_str=""
	fi
	
	# genera descrizione argomenti
	parseargs_get_config_ args
	arg_config="$__"
	for var in $arg_config; do
		[[ "$var" =~ ^- ]] && { var=${var#-} ; modifier="opt" ; } || modifier=""
		parseargs_get_default_ args "$var"
		arg_default="$__"
		parseargs_get_cmd_argopt_ __parseargs_args_tag $var
		desc="$( printf_color "$Yellow%s$Color_Off" "$( [ -n "$modifier" ] && echo '[' )<$__>$( [ -n "$arg_default" ] && printf_color "$Color_Off=$Green%s$Yellow" "$arg_default" )$( [ -n "$modifier" ] && echo ']' )" )"
		str_concat avail_args_str "$desc"
		parseargs_get_values_ args "$var"
		__="${__//||/$'\n'}"
		__="${__/re:\{*\}=}"
		arg_vals="${__//$'\n'/$Color_Off$'\n'                          $Cyan}"
		parseargs_get_cmd_argopt_ __parseargs_args_desc "$var"
		tmp="${__//$'\n'/$'\n'    }"
		if [[ -n "$arg_vals" || -n "$tmp" || -n "$arg_default" ]]; then
			str_concat info_args "$desc" $'\n\n'
			[ -n "$arg_vals" ] && info_args="$info_args"$'\n'"    $( printf_color "%-22s$Cyan%b$Color_Off" "Valori ammessi:" "$arg_vals" )"
			[ -n "$arg_default" ] && info_args="$info_args"$'\n'"    $( printf_color "%-22s$Green%s$Color_Off" "Default:" "$arg_default" )"
			[ -n "$tmp" ] && info_args="$info_args"$'\n\n'"    $tmp"
		fi
	done
	[ -n "$info_args" ] && info_args=$'\n\n'"$( printf_color "${UWhite}Descrizione argomenti$Color_Off" )"$'\n'"$info_args"
	parseargs_opt_to_real_ "${__parseargs_opts_var_to_opt[HELP]}"
	tmp="$(printf_color "$Yellow%s$Color_Off" "[$__] [<opzioni>]")"
	
	[ -n "$avail_args_str" ] && avail_args_str="$avail_args_str "
	header="Sintassi comando: $SCRIPTNAME ${cmds_match_str}${avail_cmd_str}${avail_args_str}${tmp}"

	# scrive l'header ed esce se si tratta di descrizione breve
	str_help="$header"
#	echo "$header"
	if [ "$is_short" = 0 ]; then
	
		# genera descrizione opzioni
		parseargs_get_config_ opts
		avail_opts="$__"
		for var in $avail_opts; do
			[ "$var" = parseargs-def ] && continue
			modifier="${var##*[a-z\-_|]}"
			var="${var/[:?+]*}"
			parseargs_opt_to_real_ "$var" "$modifier"
			tmp="${__//|/, }"
			[[ "$modifier" =~ : ]] && { arg="${__parseargs_opts_var[$var]}" ; arg="${arg##*#}" ; } || arg=""
			parseargs_get_values_ opts "${var}${modifier}"
			__="${__//||/$'\n'}"
			opt_vals="$( <<<"$__" sed -E 's/^re:\{[^}]*}=//' )"
			parseargs_get_cmd_argopt_ __parseargs_opts_desc "$var"
			str_concat info_options "    $( printf_color "$Yellow%-20s$Color_Off" "$tmp$( [ -n "$arg" ] && echo " <$arg>" )$( [[ "$modifier" =~ "+" ]] && echo " [...]" )" )  ${__//$'\n'/$'\n'        }" $'\n'
			[ -n "$opt_vals" ] && str_concat info_options "$( printf ' %.0s' {1..26} )Valori ammessi:
$( printf_color "$Cyan%s$Color_Off" "$( <<<"$opt_vals" sed -E "s/^/$( printf ' %.0s' {1..30} )/" )" )" $'\n'
		done
		[ -n "$info_options" ] && info_options=$'\n\n'"$( printf_color "${UWhite}Opzioni disponibili$Color_Off" )"$'\n'"$info_options"
	
		parseargs_get_cmd_argopt_ --exact __parseargs_cmds_longdesc
		[ -z "$__" ] && { parseargs_get_cmd_argopt_ __parseargs_cmds_desc ; __="Il comando $__" ; }
		define info <<EOF

$__
$( echo -n "$info_options" )\
$( echo -n "$info_cmds" )\
$( echo -n "$info_args" )
EOF
	str_concat str_help "$info" $'\n'
#	echo "$info"
	fi
	if is_flag IS_PIPED || [ "$is_short" = 1 ]; then
		echo "$str_help"
	else
		<<<"$str_help" less -R
	fi
	exit 0
}

function parseargs_init() {
	[ "$1" = --parseargs-def ] && __parseargs_is_def=1 || __parseargs_is_def=0
	declare -ga __parseargs_original_args=("$@")
}

function parseargs_config() {
	__CMDS=() __ARGS=() __OPTS=() __OPTARGS=()
	local varname key opt var var1 var2 tmp tmp2 modifier exit_args
	declare -g __parseargs_getopt_short_def __parseargs_getopt_long_def

	[ "$1" = --parseargs-eval ] && shift || exit_args="--exit 1"
	# cancella le variabili di cache, perche' le diverse istanze di bash completion vengono avviate all'interno dello stesso environment
	local var
	while read var; do
		unset $var
	done < <( set -o posix ; set | grep -oP "^__cache___parseargs[^=]*(?==)" )

	copy_hash "$1" __parseargs_cmds_config ; shift
	copy_hash "$1" __parseargs_args_config ; shift
	copy_hash "$1" __parseargs_opts_config ; shift
	copy_hash "$1" __parseargs_cmds_desc ; shift
	copy_hash "$1" __parseargs_cmds_longdesc ; shift
	copy_hash "$1" __parseargs_args_tag ; shift
	copy_hash "$1" __parseargs_args_desc ; shift
	copy_hash "$1" __parseargs_opts_var ; shift
	copy_hash "$1" __parseargs_opts_desc ; shift
	# aggiunge l'opzione --parseargs-def
	if [ -z "$( <<<"${__parseargs_opts_config[-]}" grep -w parseargs-def )" ]; then
		[[ ${__parseargs_opts_config[-]+_} && -n "${__parseargs_opts_config[-]}" ]] && __parseargs_opts_config[-]="${__parseargs_opts_config[-]} parseargs-def" || __parseargs_opts_config[-]="parseargs-def"
	fi
	__parseargs_opts_var[parseargs-def]="PARSEARGS_DEF"
	__parseargs_opts_desc[parseargs-def]="opzione di servizio: non utilizzare"
	
	# se opzione PARSEARGS_DEF attiva: scrive la definizione delle variabili ed esce
	[ "$__parseargs_is_def" = 1 ] && { parseargs_get_definition ; exit ; }
	# determina tutte le opzioni
	declare -a opt_ary1=() opt_ary2=()
	for key in "${!__parseargs_opts_config[@]}"; do
		parseargs_get_config_ opts "" $key
		var="$__"
		opt_ary1+=($var)
		opt_ary2+=("$( <<<"$var" sed -Ee ':begin s/([^|:?+ ]+)\|([^|:?+ ]+)([:?+]+)/\1\3|\2\3/g ; t begin ; s/\|/ /g' )")
	done
	var1="$( unique_words "${opt_ary1[*]}" )"
	var2="$( unique_words "${opt_ary2[*]}" )"
	# genera l'array __parseargs_opts_var_to_opt (inverso di __parseargs_opts_var)
	declare -gA __parseargs_opts_var_to_opt
	for opt in $var1; do
		tmp="${opt/[:?+]*/}"
		[ -z "${__parseargs_opts_var[$tmp]}" ] && { error_msg $exit_args "Manca il parametro '$tmp' nella variabile di configurazione OPTS_VAR" ; return 1 ; }
		[ ${__parseargs_opts_var_to_opt[$tmp]+_} ] && continue || __parseargs_opts_var_to_opt[${__parseargs_opts_var[$tmp]%#*}]="$tmp"
	done
	# configura le opzioni
	local already_present is_msg_differ
	for opt in $var2; do
		tmp="${opt//[?+]/}" is_msg_differ=0 already_present=0
		if [[ "$opt" =~ ^.[:?+]*$ ]]; then
			varname=__parseargs_getopt_short_def ;
			if [[ "$__parseargs_getopt_short_def" =~ ${tmp/:/} ]]; then
				already_present=1
				[[ ! "$__parseargs_getopt_short_def" =~ $tmp($|[^:]) ]] && is_msg_differ=1
			fi
		else
			varname=__parseargs_getopt_long_def ; 
			if [[ "$__parseargs_getopt_long_def" =~ (^|,)${tmp/:/}:?(,|$) ]]; then
				already_present=1
				[[ ! "$__parseargs_getopt_long_def" =~ (^|,)${tmp}(,|$) ]] && is_msg_differ=1
			fi
		fi
		if [ "$already_present" = 1 ]; then
			[ "$is_msg_differ" = 1 ] && warn_msg "[parseargs] Opzione '$opt' differisce nell'argomento opzionale da un'opzione già definita"
			continue
		else
			# short
			if [[ "$varname" = __parseargs_getopt_short_def ]]; then
				[[ "$opt" =~ \? ]] && { error_msg $exit_args "[parseargs] Opzione '$opt' non valida: non può essere definita un'opzione switch breve (con una sola lettera)" ; return 1 ; }
				__parseargs_getopt_short_def="$__parseargs_getopt_short_def$tmp"
			# long
			else
				str_concat __parseargs_getopt_long_def "$tmp" ,
				if [[ "$opt" =~ \? ]]; then
					[[ "$opt" =~ \+ ]] && { error_msg $exit_args "[parseargs] Opzione '$opt' non valida: non può essere definita un'opzione switch multipla" ; return 1 ; }
					__parseargs_getopt_long_def="$__parseargs_getopt_long_def,no-$tmp"
				fi
			fi
		fi
	done
}

function parseargs_parse_args() {
	local opts stderr
	# https://stackoverflow.com/questions/13806626/capture-both-stdout-and-stderr-in-bash?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
	# stdout in $opts and stderr in $stderr
	. <({ stderr=$({ opts=$( getopt -o "$__parseargs_getopt_short_def" --long "$__parseargs_getopt_long_def" -n 'parseargs' -- "$@" ); bret=$?; } 2>&1; declare -p opts bret >&2); declare -p stderr; } 2>&1)
#	local opts="$( getopt -o "$__parseargs_getopt_short_def" --long "$__parseargs_getopt_long_def" -n 'parseargs' -- "$@" )"
	[ $? != 0 ] && parseargs_error "Errore nella verifica delle opzioni: usare $SCRIPTNAME -h|--help per informazioni sull'utilizzo del comando"
	local original_args=("$@")
	eval set -- "$opts"
	declare -ga __parseargs_getopt_args=("$@")
	local args_idx_cmd=$(array_index_of __parseargs_getopt_args --)
	# Parse dei comandi
	local arg cur_cmd arg_config modifier is_arg_processed avail_cmds
	for arg in "${@:$(( $args_idx_cmd+2 ))}"; do
		cur_cmd=""
		parseargs_get_avail_cmds_
		avail_cmds="$__"
		# legge i comandi
		if [ -n "$avail_cmds" ]; then
			[[ ! "$avail_cmds" =~ (^| )$arg( |$) ]] && { parseargs_error "Comando '$arg' non valido" ; return 1 ; } || cur_cmd="$arg"
		fi
		# legge altri argomenti posizionali
		if [ -n "$cur_cmd" ]; then
			__CMDS+=( "$cur_cmd" )
			parseargs_get_avail_cmds_
			[[ "$__" =~ script\(.*\) ]] && return
		else
			parseargs_get_config_ args
			arg_config="$__"
			is_arg_processed=0
			for def_arg in $arg_config; do
				[[ "$def_arg" =~ ^- ]] && { def_arg=${def_arg#-} ; modifier="-" ; } || modifier=""
				[ -n "${__ARGS[$def_arg]}" ] && continue
				__ARGS[$def_arg]="$arg"
				is_arg_processed=1
				break
			done
			[ "$is_arg_processed" = 0 ] && { parseargs_error "Argomento '$arg' non valido" ; return 1 ; }
		fi
	done
	[[ -n "$stderr" && "$__parseargs_is_autocomplete" != 1 ]] && error_msg --exit 1 "$stderr"
}

function parseargs_parse_opts() {
	local opt_info var opt val varname opt_vals
	while [[ $# -gt 0 ]]; do
		opt="$1" val="$2"
		[ "$opt" = '--' ] && break
		shift
		parseargs_get_matched_opt_ "$opt"
		IFS="@" read -ra opt_info <<<"$__"
		[ -z "${opt_info[0]}" ] && parseargs_error "L'opzione '$opt' non è valida"
		var="${__parseargs_opts_var[${opt_info[0]}]}"
		if [[ "${opt_info[1]}" =~ : ]]; then
			shift
			parseargs_get_values_ opts "${opt_info[2]}"
			opt_vals="${__//||/$'\n'}"
			if [ -n "$opt_vals" ] && ! <<<"$( <<<"$opt_vals" grep -v "^re:{" )" grep -Fx "$val" &>/dev/null; then
				local is_match=0 regexp
				while read regexp; do
					<<<"$val" grep -P "$regexp" &>/dev/null && { is_match=1 ; break ; }
				done  < <( <<<"$opt_vals" grep "^re:{" | sed -E 's/\\/\\\\/g ; s/^re:\{// ; /\}$/ { s/\}$// ; t end } ; s/\}=.*$// ; :end' | grep -v '^$' )
				[ "$is_match" = 0 ] && parseargs_error "L'opzione $opt ha il valore '$val' non ammesso"
			fi
			__OPTS[${var%%#*}]="$val"
			[[ "${opt_info[1]}" =~ \+ ]] && eval "__OPTS_${var%%#*}+=('$val')"
		else
			(( __OPTS[$var] += ${opt_info[3]} ))
		fi
	done
	[ ${__OPTS[HELP]+_} ] && parseargs_help
}


function parseargs_check_args() {
	local arg_config def_arg modifier arg_opts literal_opts regexp_opts val regexp is_match
	# verifica se ci sono comandi mancanti
	parseargs_get_avail_cmds_
	local avail_cmds="$__"
	[ -n "$avail_cmds" ] && parseargs_error "Specifica il comando da eseguire"
	# verifica se ci sono argomenti mancanti
	parseargs_get_config_ args
	arg_config="$__"
	for def_arg in $arg_config; do
		modifier="${def_arg%%[^-]*}" def_arg="${def_arg#-}" val="${__ARGS[$def_arg]}"
		if [ -z "$val" ]; then
			parseargs_get_default_ args "$def_arg"
			default_val="$__"
			if ! [ ${__ARGS[$def_arg]+_} ] && [ -n "$default_val" ]; then
				__ARGS[$def_arg]="$default_val"
				__DEFAULTS[$def_arg]=1
			elif [ -z "$modifier" ]; then
				parseargs_get_cmd_argopt_ __parseargs_args_tag $def_arg
				parseargs_error "Manca l'argomento obbligatorio <$__>"
			fi
		else
			parseargs_get_values_ args "$def_arg"
			arg_opts="${__//||/$'\n'}"
			if [ -n "$arg_opts" ]; then
				literal_opts="$( <<<"$arg_opts" grep -v "^re:{" )"
				if ! <<<"$literal_opts" grep -Fx "$val" &>/dev/null; then
					regexp_opts="$( <<<"$arg_opts" grep "^re:{" )"
					is_match=0
					while read regexp; do
						<<<"$val" grep -P "$regexp" &>/dev/null && { is_match=1 ; break ; }
					done < <( <<<"$regexp_opts" sed -E 's/\\/\\\\/g ; s/^re:\{// ; /\}$/ { s/\}$// ; t end } ; s/\}=.*$// ; :end' | grep -v '^$' )
					[ "$is_match" = 0 ] && { parseargs_get_cmd_argopt_ __parseargs_args_tag $def_arg ; parseargs_error "L'argomento <$__> ha il valore '$val' non ammesso" ; }
				fi
			fi
		fi
	done
	merge_hash __OPTARGS __ARGS
	merge_hash __OPTARGS __OPTS
	parseargs_is_optarg TEST && test_msg "Esecuzione di test: non verrà apportata nessuna modifica"
	parseargs_is_optarg DEBUG && debug_msg "Debug abilitato: non verrà apportata nessuna modifica"
}

function parseargs_autocompletion() {
	declare -g __parseargs_is_autocomplete=1
	
	local cur_arg="${COMP_WORDS[COMP_CWORD]}"
	[ "$#" = 0 ] && local args=(${COMP_WORDS[@]:1:$(( $COMP_CWORD - 1 ))}) || local args=($@)
	parseargs_parse_args "${args[@]}"
	
	# verifica se deve richiamare un sottocomando esterno
	parseargs_get_avail_cmds_
	local avail_cmds="$__"
	if [[ "$avail_cmds" =~ script\((.*)\) ]]; then
		script_cmd="${BASH_REMATCH[1]}"
		args=("${args[@]:$(( ${#__CMDS[@]} ))}")
		eval "$( "$script_cmd" --parseargs-def )"
		parseargs_autocompletion "${args[@]}"
		return
	fi
	avail_cmds="${avail_cmds// /$'\n'}"
	
	# verifica se si tratta di opzione con argomento
	[ "${#args}" -ge 1 ] && local last_arg="${args[-1]}"
	if [[ "$last_arg" =~ ^- ]]; then
		local opt_info
		parseargs_get_matched_opt_ "$last_arg"
		IFS="@" read -ra opt_info <<<"$__"
		if [[ "${opt_info[1]}" =~ : ]]; then
			parseargs_get_values_ opts "${opt_info[2]}"
			__="${__//||/$'\n'}"
			shopt -s extglob ; local opt_vals="${__//re:\{*([^$'\n'])\}=}" ; shopt -u extglob
			[ -z "$opt_vals" ] && { opt_vals="${__parseargs_opts_var[${opt_info[0]}]}" ; opt_vals="\"<${opt_vals##*#}>\"" ; } ||
				opt_vals="\"${opt_vals//$'\n'/\"$'\n'\"}\""	# racchiude ciascuna linea con doppi apici
			readarray -t COMPREPLY < <( compgen -W "${opt_vals}" -- $cur_arg )
			return
		fi
	fi
	
	# argomenti
	parseargs_get_config_ args
	local arg_config="$__" avail_args desc arg_default arg_vals tmp
	for var in $arg_config; do
		[[ "$var" =~ ^- ]] && { var=${var#-} ; modifier="opt" ; } || modifier=""
		[ ${__ARGS[$var]+_} ] && continue
		parseargs_get_values_ args "$var"
		__="${__//||/$'\n'}"
		arg_vals="${__/re:\{*\}=}"
		if [ -n "$arg_vals" ]; then
			str_concat avail_args "\"${arg_vals//$'\n'/\"$'\n'\"}\"" $'\n'
		else
			parseargs_get_cmd_argopt_ __parseargs_args_tag $var
			while read tmp; do
				if [[ "$tmp" =~ ^\".*\"$ ]]; then
					str_concat desc "$tmp" $'\n'
				else
					[ -n "$modifier" ] && local tmp1="[<$tmp>]" || local tmp1="<$tmp>"
					str_concat desc "\"$tmp1\""
				fi
			done <<<"${__//|/$'\n'}"
			str_concat avail_args "$desc" $'\n'
		fi
		break
	done
	
	# opzioni
	parseargs_get_config_ opts
	local avail_opts="$__"
	[[ -z "$avail_cmds" && -z "$avail_args" && ! "$avail_opts" =~ " " ]] && avail_opts="${avail_opts//|/$'\n'}"
	avail_opts="${avail_opts// /$'\n'}"$'\n'
	avail_opts="${avail_opts//parseargs-def$'\n'}"
	parseargs_opt_to_real_ "$avail_opts"
	avail_opts="${__//[:?+]}"
	avail_opts="${avail_opts%$'\n'}"
	[[ "$cur_arg" =~ ^- ]] && avail_opts="${avail_opts//|/$'\n'}"
	if [[ "$cur_arg" =~ ^-- ]]; then
		avail_opts="$( <<<"$avail_opts" sed -E ':begin s/(^|\|)-[^-|[:space:]]//g ; t begin ; s/^\|//' | grep -v ^$ | sed -E 's/^--\[no-\](.*)$/--\1\n--no-\1/' )"
	fi
	
	readarray -t COMPREPLY < <( compgen -W "${avail_cmds}
${avail_opts}
${avail_args}" -- $cur_arg )
}

function parseargs_get_definition() {
	local varlist="__parseargs_cmds_config __parseargs_args_config __parseargs_opts_config __parseargs_cmds_desc __parseargs_cmds_longdesc __parseargs_cmds_longdesc __parseargs_args_tag __parseargs_args_desc __parseargs_opts_var __parseargs_opts_desc"
	
	for var in $varlist; do
		declare -p $var | sed -E 's/__parseargs//'
	done
	echo parseargs_config --parseargs-eval _cmds_config _args_config _opts_config _cmds_desc _cmds_longdesc _args_tag _args_desc _opts_var _opts_desc
}

function parseargs_parse() {
	parseargs_parse_args "${__parseargs_original_args[@]}"
	parseargs_get_avail_cmds_
	if [[ "$__" =~ script\((.*)\) ]]; then
		script_cmd="${BASH_REMATCH[1]}"
		local args=("${__parseargs_original_args[@]:$(( ${#__CMDS[@]} ))}")
		"$script_cmd" "${args[@]}"
		exit
	fi
	parseargs_parse_opts "${__parseargs_getopt_args[@]}"
#	parseargs_is_optarg DEBUG && parseargs_enable_optarg VERBOSE
	[ "${__OPTS[DEBUG]}" = 1 ] && __OPTS[VERBOSE]=1
}
