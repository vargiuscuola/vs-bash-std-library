#!/bin/bash
#github-action genshdoc

# if already sourced, return
[[ -v _CONSOLE__LOADED ]] && return || _CONSOLE__LOADED=True
declare -ga _CONSOLE__CLASSES=(console)

# @file main.sh
# @brief Library for print messages to console.
# @description Contains functions for print messages to console and manage indentation.  
#   It contains the class `console`
#   
#   Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))
# @show-internal
shopt -s expand_aliases

module.import "datatypes"
module.import "main"
module.import "args"


############
#
# SETTINGS
#

# @constant-header Terminal color codes
# @constant Color_Off Disable color
Color_Off=$'\e[0m'
# @constant Black,Red,Green,Yellow,Blue,Purple,Cyan,Orange                                   Regular Colors
Black=$'\e[0;30m' Red=$'\e[0;31m' Green=$'\e[0;32m' Yellow=$'\e[0;33m' Blue=$'\e[0;34m' Purple=$'\e[0;35m' Cyan=$'\e[0;36m' White=$'\e[0;37m' Orange=$'\e[38;5;208m'
# @constant BBlack,BRed,BGreen,BYellow,BBlue,BPurple,BCyan,BWhite                            Bold Colors
BBlack=$'\e[1;30m' BRed=$'\e[1;31m' BGreen=$'\e[1;32m' BYellow=$'\e[1;33m' BBlue=$'\e[1;34m' BPurple=$'\e[1;35m' BCyan=$'\e[1;36m' BWhite=$'\e[1;37m'
# @constant UBlack,URed,UGreen,UYellow,UBlue,UPurple,UCyan,UWhite                            Underlined Colors
UBlack=$'\e[4;30m' URed=$'\e[4;31m' UGreen=$'\e[4;32m' UYellow=$'\e[4;33m' UBlue=$'\e[4;34m' UPurple=$'\e[4;35m' UCyan=$'\e[4;36m' UWhite=$'\e[4;37m'
# @constant On_Black,On_Red,On_Green,On_Yellow,On_Blue,On_Purple,On_Cyan,On_White            Background Colors
On_Black=$'\e[40m' On_Red=$'\e[41m' On_Green=$'\e[42m' On_Yellow=$'\e[43m' On_Blue=$'\e[44m' On_Purple=$'\e[45m' On_Cyan=$'\e[46m' On_White=$'\e[47m'
# @constant IBlack,IRed,IGreen,IYellow,IBlue,IPurple,ICyan,IWhite                            High Intensty Colors
IBlack=$'\e[0;90m' IRed=$'\e[0;91m' IGreen=$'\e[0;92m' IYellow=$'\e[0;93m' IBlue=$'\e[0;94m' IPurple=$'\e[0;95m' ICyan=$'\e[0;96m' IWhite=$'\e[0;97m'
# @constant BIBlack,BIRed,BIGreen,BIYellow,BIBlue,BIPurple,BICyan,BIWhite                    Bold High Intensity Colors
BIBlack=$'\e[1;90m' BIRed=$'\e[1;91m' BIGreen=$'\e[1;92m' BIYellow=$'\e[1;93m' BIBlue=$'\e[1;94m' BIPurple=$'\e[1;95m' BICyan=$'\e[1;96m' BIWhite=$'\e[1;97m'
# @constant On_IBlack,On_IRed,On_IGreen,On_IYellow,On_IBlue,On_IPurple,On_ICyan,On_IWhite    High Intensty Background Colors
On_IBlack=$'\e[0;100m' On_IRed=$'\e[0;101m' On_IGreen=$'\e[0;102m' On_IYellow=$'\e[0;103m' On_IBlue=$'\e[0;104m' On_IPurple=$'\e[10;95m' On_ICyan=$'\e[0;106m' On_IWhite=$'\e[0;107m'


############
#
# GLOBALS
#

# @global _CONSOLE__INDENT_N Number Number of indentation levels
_CONSOLE__INDENT_N=0
# @global _CONSOLE__INDENT_NCH Number Number of characters per indentation
_CONSOLE__INDENT_NCH=4
# @global _CONSOLE__MSG_COLOR_TABLE Hash Associative array containing the color to use for every type of console message
declare -gA _CONSOLE__MSG_COLOR_TABLE=([ERROR]="$Red" [OK]="$BGreen" [WARNING]="$Yellow" [INFO]="$Cyan" [INPUT]=$'\e[38;5;141m' [TEST]="$Orange" [DEBUG]="$Orange")


############
#
# CONSOLE FUNCTIONS
#
############


console_set-indent-level() {
  _CONSOLE__INDENT_N=$1
}
alias console.set-indent-level="console_set-indent-level"

# @description Set the indentation size (number of spaces).
# @arg $1 Number Number of spaces per indentation
console_set-indent-size() {
  _CONSOLE__INDENT_NCH=$1
}
alias console.set-indent-size="console_set-indent-size"

# @description Add the indentation level.
# @arg $1 Number Number of indentation level to add
console_add-indent() {
  (( _CONSOLE__INDENT_N += 1 ))
}
alias console.add-indent="console_add-indent"

# @description Subtract the indentation level.
# @arg $1 Number Number of indentation level to subtract
console_sub-indent() {
  [ "$_CONSOLE__INDENT_N" -gt 0 ] && (( _CONSOLE__INDENT_N -= 1 ))
}
alias console.sub-indent="console_sub-indent"

# @description Print the spaces consistent to the current indentation level.
console_print-indent() {
  local i indent_str

  eval "printf ' %.0s' {1..$(($_CONSOLE__INDENT_NCH*$_CONSOLE__INDENT_N))}"
}
alias console.print-indent="console_print-indent"


# @description Get extended terminal color codes
#
# @arg $1 number Foreground color
# @arg $2 number Background color
#
# @example
#   get_ext_color 208
#     => \e[38;5;208m
#
# @exitcode NA
#
# @stdout Color code.
console_get-extended-color() {
  declare -a colors
  [ -n "$1" ] && colors+=("38;5;$1")
  [ -n "$2" ] && colors+=("48;5;$1")
  local bck_ifs="$IFS"
  IFS=';'
  declare -g __
  printf -v __ "%b" "\e[${colors[*]}m"
  IFS="$bck_ifs"
}
alias console.get-extended-color="console_get-extended-color"


# @description Print a message of the type provided.
#   The format of the message is `[<message-type>] <msg>`. The message type is colorized with same default color specific for every type of message (it can be customized with the `--color` parameter).
#   When piped, the function doesn't colorize the message type unless the settings COLORIZE_OUTPUT is enabled (`settings.enable COLORIZE_OUTPUT`).
# @alias console.msg
# @arg $1 The type of message (written in square brackets). If type is `ERROR`, then by default the message will be written to stderr (can be overriden by the `--stdout` option)
# @arg $2..@ The message to print
# @opt --show-function Prefix the message with the calling function
# @opt --exit <n> Exit the script with the <n> status code
# @opt -n Don't print the ending newline
# @opt -e Interpret special characters
# @opt --color <color> Print the type of message (first argument) with the color specified
# @opt --stderr Print the message to stderr (can't be set together with the `--stdout` parameter)
# @opt --stdout Print the message to stdout (can't be set together with the `--stderr` parameter)
# @opt --tty Print the message to console
# @opt --indent Prefix the message with the indentation
# @exitcodes Standard
# @stdout Print the message
console_msg() {

  declare -A __opts
  declare -a __args
  args.parse __opts __args -- --show-function --exit: -n -e --color: --stderr --stdout --tty --indent -- "$@"
  (( ${#__args[@]} < 1 )) && { errmsg "Missing the argument with the type of message" ; raise ; }
  (( ${#__args[@]} < 2 )) && { errmsg "Missing the argument with the message to print" ; raise ; }

  declare -a add_args=()
  local type msg color exit_code is_stderr function_info

  # if --show-function option, then add the function name to the message
  [ -v "__opts[show-function]" ] && function_info="${FUNCNAME[1]}()# "

  type="${__args[0]}"
  exit_code=${__opts[exit]}
  [ -v "__opts[n]" ] && add_args+=(-n)
  [ -v "__opts[e]" ] && add_args+=(-e)
  color=${__opts[color]}
  [ -z "$color" ] && color="${_CONSOLE__MSG_COLOR_TABLE[$type]}"

  # check if message should be sent to stderr
  [[ ( "$type" = ERROR || -v "__opts[stderr]" ) && ! -v "__opts[stdout]" ]] && is_stderr=1
  
  # if tty or stderr option...  
  if [[ -v "__opts[tty]" || "$is_stderr" = 1 ]]; then
    
    fd.get_ ; local fd_stdout="$__"
    
    if [ -v "__opts[tty]" ]; then
      eval "exec $fd_stdout>&1 >/dev/tty"
    elif [ "$is_stderr" = 1 ]; then
      eval "exec $fd_stdout>&1 >&2"
    fi

  fi
  
  # add indentation if `--indent` parameter is set
  [ -v "__opts[indent]" ] && console.print-indent
  
  # add message type with color or not depending on the `COLORIZE_OUTPUT` setting and/or the current script/function is piped
  if settings.is_enabled COLORIZE_OUTPUT || [ -t 1 ]; then
    echo -n "$color"[$type]"$Color_Off "
  else
    echo -n "[$type] "
  fi
  echo ${add_arg[@]} "${function_info}""${__args[@]:1}"

  # restore the stdout and stderr if needed
  [[ "$is_stderr" = 1 || -v "__opts[tty]" ]] && eval "exec >&$fd_stdout $fd_stdout>&-" || true
  
  # if exit code is set, then exit
  [ -n "$exit_code" ] && exit "$exit_code" || return 0

}
alias console.msg="console_msg"

# define aliases for other types of messages
for _CONSOLE__TYPE_MSG in INPUT OK ERROR INFO WARN TEST DEBUG; do
  [ "$_CONSOLE__TYPE_MSG" = INPUT ] && _CONSOLE__ADD_ARG="--tty " || _CONSOLE__ADD_ARG=""
  alias console_${_CONSOLE__TYPE_MSG,,}="console_msg --color '${_CONSOLE__MSG_COLOR_TABLE[$_CONSOLE__TYPE_MSG]}' $_CONSOLE__ADD_ARG $_CONSOLE__TYPE_MSG"
  alias console.${_CONSOLE__TYPE_MSG,,}="console_msg --color '${_CONSOLE__MSG_COLOR_TABLE[$_CONSOLE__TYPE_MSG]}' $_CONSOLE__ADD_ARG $_CONSOLE__TYPE_MSG"
done


# @description Print a message with printf syntax.
#   The output is left untouched if the setting `COLORIZE_OUTPUT` is enabled (`settings.enable COLORIZE_OUTPUT`) or if the output is not piped, otherwise the color codes are removed.
# @stdout Print the message
console_printf() {
  
  # is COLORIZE_OUTPUT is enabled or the output is not piped
  if settings.is_enabled COLORIZE_OUTPUT || [ -t 1 ]; then
    printf "$@"
  # otherwise color codes are removed
  else
    printf "$@" | sed -r "s/\x1B\[([0-9]{1,3};){0,2}[0-9]{0,3}[mGK]//g"
  fi
}
alias console.printf="console_printf"
