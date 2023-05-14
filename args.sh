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


############
#
# GLOBALS
#

# @global _ARGS__ERROR_CODE Number Error code returned when validation of arguments fail
declare -g _ARGS__ERROR_CODE=99


############
#
# SETTINGS
#

# @constant _ARGS__BRED String Red terminal color code
_ARGS__BRED='\e[1;31m'
# @constant _ARGS__YELLOW String Yellow terminal color code
_ARGS__YELLOW='\e[0;33m'
# @constant _ARGS__CYAN String Cyan terminal color code
_ARGS__CYAN='\e[0;36m'
# @constant _ARGS__COLOR_OFF String Terminal code to turn off color
_ARGS__COLOR_OFF='\e[0m'


############
#
# ARGS FUNCTIONS
#
############

# alias to print a coloured error message
alias errmsg='>&2 echo -e "${_ARGS__BRED}[ERROR]${_ARGS__COLOR_OFF} ${_ARGS__YELLOW}${FUNCNAME[0]}()${_ARGS__COLOR_OFF}#"'

# raise an error, returning if interactive shell or exiting otherwise
alias raise='[ "${_SETTINGS__HASH[INTERACTIVE]}" = "$True" ] && return $_ARGS__ERROR_CODE || exit $_ARGS__ERROR_CODE'

# @internal
# @description Validate the number of arguments, writing an error message and exiting if the check is not passed.  
#   This is an helper function: don't use it directly, use `args_check-number` or his alias `args.check-number` instead.
# @arg $1 Number The number of arguments to be validated against the number provided in $2, or the interval $2..$3
# @arg $2 Number The minimum number of arguments (if $2 is provided), or the mandatory number or arguments (if $2 is not provided)
# @arg $3 Number (Optional) Maximum number of arguments: can be `-` if there is no limit on the number of maximum arguments
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
#   This is actually an alias which resolve to `:args_check-number $#`, useful to get the number of arguments `$#` from the calling function.
# @alias args.check-number
# @arg $1 Number The minimum number of arguments (if $2 is provided), or the mandatory number or arguments (if $2 is not provided)
# @arg $2 Number (Optional) Maximum number of arguments: can be `-` if there is no limit on the number of maximum arguments
# @exitcodes Standard (0 on check passed, 1 otherwise)
# @stderr Print an error message in case of failed validation
# @example
#   $ args.check-number 2
#   $ alias alias2="alias1"
#   $ main.dereference-alias_ "github/vargiuscuola/std-lib.bash/main"
#   # return __="func1"
alias -- args_check-number >&- 2>&- && unalias args_check-number  # if alias `args_check-number` is defined, then unalias it
args_check-number() { :; }  # define function if alias is not already defined (see following line: why such a workaround?!)
alias args_check-number=':args_check-number $#'
alias args.check-number=':args_check-number $#'

# @description Parse the command line options.
#   It store the parsed options and remaining arguments to the provided variables.
#   The standard wasy to call it is `declare -A opts ; declare -a args ; args.parse opts args -- <option-definition>... -- "$@"`
#   In addition to getopt syntax, the form `-n:,--name` is allowed, which means that the same option can be interchangebly provided in the form `-n <value>` and `--name <value>`.
#   The code and functionalities is a mix of the following two github projects:
#   * [reconquest/args](https://github.com/reconquest/args)
#   * [reconquest/opts.bash](https://github.com/reconquest/opts.bash)
# @alias args.parse
# @arg $1 Hashname Variable name of an associative array where to store the parsed options. If the character dash `-` is provided, the variables `_opts` and `_args` are used for storing the options and arguments respectively
# @arg $2 Arrayname (Optional, only provided if first argument is not a dash `-`) Variable name of an array where to store the arguments. If not provided, the arguments are printed to stdout
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
#   $ args.parse opts args 2 3 -- -av -b: -n:,--name -- -aav --name=somename arg1
#   [ERROR] Wrong number of arguments: 1 instead of 2..3
args_parse() {
  # check the first two arguments (variable name for options and arguments)
  (( $# < 1 )) && { errmsg "First argument should be name of the variable to store the parsed options to" ; raise ; }
  (( $# < 2 )) && { errmsg "Second argument should be name of the variable to store the positional arguments to" ; raise ; }
  local opts_varname="$1"
  if [[ "$opts_varname" = - ]]; then
    declare -gA _opts
    declare -ga _args
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
  [[ "$1" != -- ]] && { errmsg "-- must be present before the options definition" ; return 2 ; }
  shift
  
  local -a short_opts
  local -a long_opts
  local -a variants ary
  local -A values
  local -A aliases
  local -A tags
  local arg opt alias value tag key len

  #
  # Parse configuration options
  #
  while (( $# > 0 )); do
    arg=${1%%,*}
    # remove the leading dash characters
    [[ "$arg" =~ -*(.*)$ ]] && opt="${BASH_REMATCH[1]}" # CAREFUL: a dependant command to the regular expression match is needed, as it is not parsed otherwise
    
    tag=
    case "$1" in
      --)
        break
        ;;

      -*{*)
        tag="${opt%\}}"
        tag="${tag#*{}"
        opt="${opt%{*}"
        ;;&

      -*:*)
        opt="${opt%:}"
        values[$opt]=true
        ;;&

      -*)

        IFS="," read -ra variants <<< "$1" # split the argument with coma character
        
        ary=() # array containing the list of short options provided with the syntax `-avp`

        [[ $arg =~ ^-- ]] &&
          
          # if option start with double dash, just assign variants found until now
          variants=("$opt" "${variants[@]:1}") ||
          
          # if option start with single dash, split by each character (example format `-av`)
          {
            # ${opt//?/(.)} => convert every caharcter of the string into `(.)`, then store every match (i.e. every character) into ary
            [[ "$opt" =~ ${opt//?/(.)} ]] && ary=( "${BASH_REMATCH[@]:1}" ) # CAREFUL: a dependant command to the regular expression match is needed, as it is not parsed otherwise
            
            # the number of variants is equal to the size of array variants minus 1 (the first option itself)
            if [[ "${#ary[@]}" > 1 ]]; then
              
              [[ "${#variants[@]}" > 1 ]] && { errmsg "You can't both use the multiple short-option format (\`-avp\`) together with the aliases format (\`-h,--help\`) as in \`-hx,--help\`" ; return 3 ; }
              [ -n "$tag" ] && { errmsg "You can't provide a tag when using the multiple short-option format (\`-avp\`)" ; return 4 ; }
              [ "${values[$opt]}" = true ] && { errmsg "You can't provide the : modifier (required argument for option) when using the multiple short-option format (\`-avp\`)" ; return 5 ; }
        
            fi

            variants=("${ary[@]}" "${variants[@]:1}")
            opt="${ary[0]}"
          }

        # for each variant
        for alias in ${variants[@]}; do
        
          # remove the leading dash characters
          [[ "$alias" =~ -*(.*)$ ]] && alias="${BASH_REMATCH[1]}" # CAREFUL: a dependant command to the regular expression match is needed, as it is not parsed otherwise
          len="${#alias}" # length of option (useful for determining if it's a short or long option)

          # if a tag is provided, then it will set in the `tags` hash
          if [ -n "$tag" ]; then
            tags[$alias]=$tag
          # otherwise, if the multi short-option format is used, the aliases will reference the main (first) option
          elif [[ "${#ary[@]}" = 1 && "$alias" != "$opt" ]]; then
            aliases[$alias]="$opt"
          fi

          if [[ ${values[$opt]+x} ]]; then
            values[${alias}]=true
            alias+=":"
          fi
          
          [[ "$len" > 1 ]] && long_opts+=("$alias") || short_opts+=("$alias")

        done

        ;;

      *)
        echo "error: unexpected argument: '$opt'"
        return 2
        ;;
    esac

    shift
  done >&2

  # expecting the `--` separator: return with an error if not found
  [[ "$1" != "--" ]] && { errmsg "-- must be present and delimit options definition from incoming args string" ; return 2 ; }
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

  #
  # Parse options
  #
  while (( $# )); do
    case "$1" in
      --)
        shift
        break
        ;;

      -*)
        opt=$1

        # set the key for the option value to: 1) the tag if existing, otherwise to the option itself
        if [[ ${tags[$opt]+x} ]]; then 
          key="${tags[${opt}]}"
        else
          key="${opt}"
          key="${opt#-}"
          key="${key#-}"
        fi

        # if the option expect an argument
        if [[ ${values[$key]+x} ]]; then
          shift
          _opts[$key]=$1
        # otherwise the value of the option get incremented
        else
          _opts[$key]=$(( ${_opts[$key]:-0}+1 ))
        fi
        ;;
    esac
    value="${_opts[$key]:-}"
    shift

    # if the options is associated to a tag, then skip to the next option
    [[ ${tags[${opt}]+x} ]] && continue
    
    # if current option is an alias, find and set the original option
    opt="${aliases[$key]:-}"
    [[ "${opt:-}" ]] && _opts[$opt]="$value"
    
    # set all aliases
    for alias in "${!aliases[@]}"; do

      if [[ "${aliases[$alias]}" = "$key" ]]; then
        _opts[$alias]="$value"
      fi
      
    done

  done
  
  # set the arguments
  _args=("$@")
  
  # print the options and arguments to stdout if variable names are not provided
  #if [ "$opts_varname" = - ]; then
  #  echo -e "\e[0;33m# Options:${_ARGS__COLOR_OFF}"
  #  paste -d' ' <(printf '%s\n' "${!_opts[@]}") <(printf '%q\n' "${_opts[@]}")
  #  if (( "${#_args[@]}" )); then
  #    echo -e "${_ARGS__YELLOW}# Arguments:${_ARGS__COLOR_OFF}"
  #    printf '%q\n' "${_args[@]}"
  #  else
  #    echo -e "${_ARGS__YELLOW}# No Arguments${_ARGS__COLOR_OFF}"
  #  fi
  #fi
  
  # validate the number of arguments
  if [ -n "$min_args" ]; then
    args_check-number "$min_args" "$max_args" || return $_ARGS__ERROR_CODE
  fi
}
alias args.parse="args_parse"


# @description Check if the specified option has been provided to a previous call to function `args.parse`
# @arg $1 String The option whose value you want to check
# @arg $2 String (Optional) The variable name containing the options: if not provided, it will use the default variable name defined in the function `args.parse`
# @alias args.is-opt_
args_is-opt() {
  args_check-number 1 2 || return 1
  
  [ -n "$2" ] && local opts_varname="$2" || local opts_varname=_opts
  declare -n __args_is_opt__opts="$opts_varname"
  [[ ${__args_is_opt__opts["$1"]+x} ]]
}
alias args.is-opt="args_is-opt"

# @description Get the value of the option provided to a previous call to function `args.parse`
# @arg $1 String The option whose value you want to get
# @arg $2 String (Optional) The variable name containing the options: if not provided, it will use the default variable name defined in the function `args.parse`
# @alias args.get-opt_
# @return The value of the provided option
args_get-opt_() {
  args_check-number 1 2 || return 1
  
  [ -n "$2" ] && local opts_varname="$2" || local opts_varname=_opts
  declare -n __args_is_opt__opts="$opts_varname"
  declare -g __="${__args_is_opt__opts["$1"]}"
}
alias args.get-opt_="args_get-opt_"