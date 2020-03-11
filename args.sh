#!/bin/bash
#github-action genshdoc

# @file args.sh
# @brief Provide argument parsing functionalities
# @show-internal
shopt -s expand_aliases

# @global _ARGS__RED String Red terminal color code
_ARGS__RED='\e[0;31m'
# @global _ARGS__YELLOW String Yellow terminal color code
_ARGS__YELLOW='\e[0;33m'
# @global _ARGS__CYAN String Cyan terminal color code
_ARGS__CYAN='\e[0;36m'
# @global _ARGS__COLOR_OFF String Terminal code to turn off color
_ARGS__COLOR_OFF='\e[0m'

# alias to print a coloured error message
alias errmsg='echo -e "${_ARGS__RED}[ERROR]${_ARGS__COLOR_OFF} ${_ARGS__YELLOW}${FUNCNAME[0]}${_ARGS__COLOR_OFF}#"'

# @description Parse the command line options.
#   It store the parsed options and remaining arguments to the provided variables.
#   Additionally to getopt syntax, it allows aliases provided in the following form:
#   * -n:,--name
#   which, in this case, means that the same option can be interchangebly provided in the form `-n <value>` and `--name <value>`.
#   The code and functionalities is a mix of the following two github projects:
#   * [reconquest/args](https://github.com/reconquest/args)
#   * [reconquest/opts.bash](https://github.com/reconquest/opts.bash)
# @alias args.parse
# @arg $1 Hashname Variable name of an associative array where to store the parsed options. If the character dash `-` is provided, the parsed options and arguments are printed in stdout
# @arg $2 Arrayname (Optional, only provided if first argument is not a dash `-`) Variable name of an array where to store the arguments
# @arg $@ Options definition and options to parse separated by --
# @exitcodes Standard
# @stdout Parsed options and arguments, only if `-` is passed as the first argument
# @example
#   $ declare -A opts ; declare -a args
#   $ args.parse opts args -av -b: -n:,--name -- -aav --name=somename arg1 arg2
#   $ declare -p opts
#   declare -A opts=([-v]="1" [-a]="2" [-n]="pippo" [--name]="pippo" )
#   $ declare -p args
#   declare -a args=([0]="arg1" [1]="arg2")
#   $ args.parse - -av -b: -n:,--name -- -aav --name=somename arg1 arg2
#   ### args_parse
#   # Options:
#   -v 1
#   -a 2
#   -n somename
#   --name somename
#   # Arguments:
#   arg1
#   arg2
#   #- args_parse

args_parse() {
	(( $# < 1 )) && { errmsg "first argument should be name of the variable to return parsed options" ; return 3 ; } >&2
	(( $# < 2 )) && { errmsg "second argument should be name of the variable to return positional arguments" ; return 3 ; } >&2
	local opts_varname="$1"
	if [[ "$opts_varname" = - ]]; then
		declare -A _opts
		declare -a _args
		shift
	else
		declare -n _opts="$opts_varname"
		declare -n _args="$2"
		shift 2
	fi
	
	local -a short_opts
	local -a long_opts
	local -a variants
	local -A values
	local -A aliases
	
	# parse options configuration
	while (( $# > 0 )); do
		opt=${1%%,*}

		case "$1" in
			--)
				break
				;;
			-*:*) 
				values[${opt%:}]=true
				;;&
			-*,-*)
				IFS="," read -ra variants <<< "${1#*,}"

				for alias in "${variants[@]}"; do
					aliases[$alias]=${opt%:}

					if ${values[${opt%:}]:-false}; then
						values[${alias}]=true
						alias+=":"
					fi
					
					[[ "${alias}" =~ ^-- ]] && long_opts+=(${alias#--*}) || short_opts+=(${alias#-*})~~
				done

				;;&
			--*)
				long_opts+=(${opt#--*})
				;;
			-*)
				short_opts+=(${opt#-*})
				;;
			*)
				echo "error: unexpected argument: '$opt'"
				return 2
				;;
		esac

		shift
	done >&2
	
	[[ "$1" != "--" ]] && { errmsg "-- must present and delimit options from incoming args string" ; return 2 ; } >&2
	shift

	_opts=()
	_args=()
	(( $# == 0 )) && return 0
	
	# parse options with getopt
	eval set -- $(
		getopt \
			-o "$(printf "%s" "${short_opts[@]:-}")" \
			${long_opts:+-l "$(printf "%s," "${long_opts[@]}")"} \
			-- "${@}"
	)
	(( $? != 0 )) && return 1
	
	# set the options
	local opt alias value
	while (( $# )); do
		case "$1" in
			--)
				shift
				break
				;;
			-*)
				opt=$1

				if ! ${values[$opt]:-false}; then
					_opts[$opt]=$(( ${_opts[$opt]:-0}+1 ))
				else
					shift
					_opts[$opt]=$1
				fi
				;;
		esac
		value="${_opts[$opt]:-}"

		# if current option is an alias, find and set the original option
		if [[ "${aliases[$opt]:-}" ]]; then
			opt="${aliases[$opt]:-}"
			_opts[$opt]="$value"
		fi
		
		# set all aliases
		for alias in "${!aliases[@]}"; do
			if [[ "${aliases[$alias]}" == "$opt" ]]; then
				_opts[$alias]=${_opts[$opt]}
			fi
		done

		shift
	done
	
	# set the arguments
	_args=("$@")
	
	if [[ "$opts_varname" = - ]]; then
		echo -e "${_ARGS__CYAN}### ${FUNCNAME[0]}${_ARGS__COLOR_OFF}\n\e[0;33m# Options:${_ARGS__COLOR_OFF}"
		paste -d' ' <(printf '%s\n' "${!_opts[@]}") <(printf '%q\n' "${_opts[@]}")
		if (( "${#_args[@]}" )); then
			echo -e "${_ARGS__YELLOW}# Arguments:${_ARGS__COLOR_OFF}"
			printf '%q\n' "${_args[@]}"
		else
			echo -e "${_ARGS__YELLOW}# No Arguments${_ARGS__COLOR_OFF}"
		fi
		echo -e "${_ARGS__CYAN}#- ${FUNCNAME[0]}${_ARGS__COLOR_OFF}"
	fi
}
alias args.parse="args_parse"
