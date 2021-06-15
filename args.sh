#!/bin/bash
#github-action genshdoc

# if already sourced, return
[[ -v _ARGS__LOADED ]] && return || _ARGS__LOADED=True

# @file args.sh
# @brief Provide argument parsing functionalities
# @description Basic argument parsing functionalities.  
#   The code and functionalities of the functon `args_parse` is a mix of the following two github projects:
#   * [reconquest/args](https://github.com/reconquest/args)
#   * [reconquest/opts.bash](https://github.com/reconquest/opts.bash)
#   
#   Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))
# @show-internal
shopt -s expand_aliases

# @global _ARGS__BRED String Red terminal color code
_ARGS__BRED='\e[1;31m'
# @global _ARGS__YELLOW String Yellow terminal color code
_ARGS__YELLOW='\e[0;33m'
# @global _ARGS__CYAN String Cyan terminal color code
_ARGS__CYAN='\e[0;36m'
# @global _ARGS__COLOR_OFF String Terminal code to turn off color
_ARGS__COLOR_OFF='\e[0m'
# @global _ARGS__ERROR_CODE Number Error code returned when validation of arguments fail
_ARGS__ERROR_CODE=99

# alias to print a coloured error message
alias errmsg='echo -e "${_ARGS__BRED}[ERROR]${_ARGS__COLOR_OFF} ${_ARGS__YELLOW}${FUNCNAME[0]}()${_ARGS__COLOR_OFF}#"'

# raise an error, returning if interactive shell or exiting otherwise
alias raise='[ "${_MAIN__FLAGS[INTERACTIVE]}" = "$True" ] && return $_ARGS__ERROR_CODE || exit $_ARGS__ERROR_CODE'

# @internal
# @description Validate the number of arguments, writing an error message and exiting if the check is not passed.  
#   This is an helper function: don't use it directly, use `args_check-number` or his alias `args.check-number` instead.
:args_check-number() {
  : trap.suspend-trace
  local max="${3:-$2}"
  [[ "$max" = - ]] && max="$1"
  (( "$1" < "$2" || "$1" > "${max}" )) && {
    [[ "${FUNCNAME[1]}" == args_parse ]] && local idx_stack=2 || local idx_stack=1
    # $2${3:+..}${3} => $2 (if $3 is not provided), or $2..$3 (if $3 is provided)
    errmsg "Wrong number of arguments in ${_ARGS__YELLOW}${FUNCNAME[$idx_stack]}()${_ARGS__COLOR_OFF}: $1 instead of $2${3:+..}${3}"
    raise
  } || true
}

# @description Validate the number of arguments, writing an error message and exiting if the check is not passed.  
#   This is actually an alias defined as `:args_check-number $#`.
# @alias args.check-number
# @arg $1 Number The number of arguments to be validated against the number provided in $2, or the interval $2..$3
# @arg $2 Number The minimum number of arguments (if $3 is provided), or the mandatory number or arguments (if $3 is not provided)
# @arg $2 Number (Optional) Maximum number of arguments: can be `-` if there is no limit on the number of maximum arguments
# @exitcodes Standard (0 on success, 1 on fail)
# @stderr Print an error message in case of failed validation
# @example
#   $ args.check-number 2
#   $ alias alias2="alias1"
#   $ main.dereference-alias_ "github/vargiuscuola/std-lib.bash/main"
#   # return __="func1"
alias -- args_check-number >&- 2>&- && unalias args_check-number
args_check-number() { :; }   # define function if alias is not already defined (see following line: why such a workaround?!)
alias args_check-number=':args_check-number $#'
alias args.check-number=':args_check-number $#'

# @description Parse the command line options.
#   It store the parsed options and remaining arguments to the provided variables.
#   In addition to getopt syntax, the form `-n:,--name` is allowed, which means that the same option can be interchangebly provided in the form `-n <value>` and `--name <value>`.
#   The code and functionalities is a mix of the following two github projects:
#   * [reconquest/args](https://github.com/reconquest/args)
#   * [reconquest/opts.bash](https://github.com/reconquest/opts.bash)
# @alias args.parse
# @arg $1 Hashname Variable name of an associative array where to store the parsed options. If the character dash `-` is provided, the parsed options and arguments are printed in stdout
# @arg $2 Arrayname (Optional, only provided if first argument is not a dash `-`) Variable name of an array where to store the arguments
# @arg $3 Number (Optional) The minimum number of arguments (if $4 is provided), or the mandatory number or arguments (if $4 is not provided)
# @arg $4 Number (Optional) Maximum number of arguments
# @arg $5 String Literal `--`: used as a separator for the following arguments
# @arg $@ String Options definition and arguments to parse separated by `--`
# @exitcodes Standard
# @stdout Parsed options and arguments, only if `-` is passed as the first argument
# @example
#   # Example n. 1
#   $ declare -A opts ; declare -a args
#   $ args.parse opts args -- -av -b: -n:,--name -- -aav --name=somename arg1 arg2
#   $ declare -p opts
#   declare -A opts=([-v]="1" [-a]="2" [-n]="pippo" [--name]="pippo" )
#   $ declare -p args
#   declare -a args=([0]="arg1" [1]="arg2")
#   # Example n. 2
#   $ args.parse - -- -av -b: -n:,--name -- -aav --name=somename arg1 arg2
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
#   # Example n. 3
#   $ args.parse opts args 2 3 -- -av -b: -n:,--name -- -aav --name=somename arg1
#   [ERROR] Wrong number of arguments: 1 instead of 2..3
args_parse() {
  # check the first two arguments (variable name for options and arguments)
  (( $# < 1 )) && { errmsg "First argument should be name of the variable to store the parsed options to" ; raise ; } >&2
  (( $# < 2 )) && { errmsg "Second argument should be name of the variable to store the positional arguments to" ; raise ; } >&2
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
  
  # check the next two optionals arguments (regarding the check of the number of arguments)
  local min_args= max_args=
  if [[ "$1" != -- ]]; then
    min_args="$1"
    shift
    [[ "$1" != -- ]] && { max_args="$1" ; shift ; }
  fi
  [[ "$1" != -- ]] && { errmsg "-- must be present before the options definition" ; return 2 ; } >&2
  shift
  
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
  
  [[ "$1" != "--" ]] && { errmsg "-- must be present and delimit options definition from incoming args string" ; return 2 ; } >&2
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
  
  # validate the number of arguments
  if [ -n "$min_args" ]; then
    args_check-number "$min_args" "$max_args" || return $_ARGS__ERROR_CODE
  fi
}
alias args.parse="args_parse"
