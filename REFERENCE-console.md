# main.sh

Library for print messages to console.

# Overview

Contains functions for print messages to console and manage indentation.  
  It contains the class `console`
  
  Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))


# Constants

## Terminal color codes
* **Color_Off**: Disable color
* **Black,Red,Green,Yellow,Blue,Purple,Cyan,Orange**: Regular Colors
* **BBlack,BRed,BGreen,BYellow,BBlue,BPurple,BCyan,BWhite**: Bold Colors
* **UBlack,URed,UGreen,UYellow,UBlue,UPurple,UCyan,UWhite**: Underlined Colors
* **On_Black,On_Red,On_Green,On_Yellow,On_Blue,On_Purple,On_Cyan,On_White**: Background Colors
* **IBlack,IRed,IGreen,IYellow,IBlue,IPurple,ICyan,IWhite**: High Intensty Colors
* **BIBlack,BIRed,BIGreen,BIYellow,BIBlue,BIPurple,BICyan,BIWhite**: Bold High Intensity Colors
* **On_IBlack,On_IRed,On_IGreen,On_IYellow,On_IBlue,On_IPurple,On_ICyan,On_IWhite**: High Intensty Background Colors


# Global Variables

* **\_CONSOLE__INDENT_N** (Number): Number of indentation levels
* **\_CONSOLE__INDENT_NCH** (Number): Number of characters per indentation
* **\_CONSOLE__MSG_COLOR_TABLE** (Hash): Associative array containing the color to use for every type of console message


# Functions
* [console_set-indent-size()](#console_set-indent-size)
* [console_add-indent()](#console_add-indent)
* [console_sub-indent()](#console_sub-indent)
* [console_print-indent()](#console_print-indent)
* [console_get-extended-color()](#console_get-extended-color)
* [console_msg()](#console_msg)
* [console_printf()](#console_printf)
* [console_finalize-readkeys()](#console_finalize-readkeys)
* [console_init-readkeys()](#console_init-readkeys)
* [console_readkeys()](#console_readkeys)


## console_set-indent-size()

Set the indentation size (number of spaces).

### Arguments

* **$1** (Number): Number of spaces per indentation

## console_add-indent()

Add the indentation level.

### Arguments

* **$1** (Number): Number of indentation level to add

## console_sub-indent()

Subtract the indentation level.

### Arguments

* **$1** (Number): Number of indentation level to subtract

## console_print-indent()

Print the spaces consistent to the current indentation level.

## console_get-extended-color()

Get extended terminal color codes

### Arguments

* **$1** (number): Foreground color

### Arguments

* **$2** (number): Background color

### Example

```bash
get_ext_color 208
  => \e[38;5;208m
```

### Exit codes

* NA

### Output on stdout

* Color code.

## console_msg()

Print a message of the type provided.
  The format of the message is `[<message-type>] <msg>`. The message type is colorized with same default color specific for every type of message (it can be customized with the `--color` parameter).
  When piped, the function doesn't colorize the message type unless the settings COLORIZE_OUTPUT is enabled (`settings.enable COLORIZE_OUTPUT`).

### Aliases

* **console.msg**

### Arguments

* **$1** (The): type of message (written in square brackets). If type is `ERROR`, then by default the message will be written to stderr (can be overriden by the `--stdout` option)
* $2..@ The message to print

### Options

* **--show-function**: Prefix the message with the calling function
* **--exit**: <n> Exit the script with the <n> status code
* **-n**: Don't print the ending newline
* **-e**: Interpret special characters
* **--color**: <color> Print the type of message (first argument) with the color specified
* **--stderr**: Print the message to stderr (can't be set together with the `--stdout` parameter)
* **--stdout**: Print the message to stdout (can't be set together with the `--stderr` parameter)
* **--tty**: Print the message to console
* **--indent**: Prefix the message with the indentation

### Exit codes

* Standard

### Output on stdout

* Print the message

## console_printf()

Print a message with printf syntax.
  The output is left untouched if the setting `COLORIZE_OUTPUT` is enabled (`settings.enable COLORIZE_OUTPUT`) or if the output is not piped, otherwise the color codes are removed.

### Output on stdout

* Print the message

## console_finalize-readkeys()

Used to restore the IFS and stty for non-blocking `console.readkeys` function.
  You need to call it after you finished to use the `console.readkeys` function.

### Aliases

* **console.finalize-readkeys**

## console_init-readkeys()

Needed to initialize the stty before using the `console.readkeys` function.

### Aliases

* **console.init-readkeys**

## console_readkeys()

Read the pressed keys in non-blocking manner: it will return the keys pressed in the buffer.
  Before using this function you need to call the `console.init-readkeys` function and when done, you need to call the `console.finalize-readkeys` function.

### Aliases

* **console.readkeys**

### Return with global scalar $__, array $__a or hash $__h

* The pressed key(s)

### Example

```bash
while true; do
  echo -n .
  console.readkeys && { echo "pressed key=$__" ; break ; }
  sleep 1
done
console.finalize-readkeys
```


