# args.sh

Provide argument parsing functionalities

# Overview

Basic argument parsing functionalities.  
  The code and functionalities of the functon `args_parse` is a mix of the following two github projects:
  * [reconquest/args](https://github.com/reconquest/args)
  * [reconquest/opts.bash](https://github.com/reconquest/opts.bash)
  
  Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))


# Global Variables

* **\_ARGS__BRED** (String): Red terminal color code
* **\_ARGS__YELLOW** (String): Yellow terminal color code
* **\_ARGS__CYAN** (String): Cyan terminal color code
* **\_ARGS__COLOR_OFF** (String): Terminal code to turn off color
* **\_ARGS__ERROR_CODE** (Number): Error code returned when validation of arguments fail


# Functions
* [args_check-number()](#args_check-number)
* [args_parse()](#args_parse)


## args_check-number()

Validate the number of arguments, writing an error message and exiting if the check is not passed.  
  This is actually an alias which resolve to `:args_check-number $#`, useful to get the number of arguments `$#` from the calling function.

### Arguments

* **$1** (Number): The minimum number of arguments (if $2 is provided), or the mandatory number or arguments (if $2 is not provided)
* **$2** (Number): (Optional) Maximum number of arguments: can be `-` if there is no limit on the number of maximum arguments

### Exit codes

* Standard (0 on success, 1 on fail)

### Output on stderr

* Print an error message in case of failed validation

### Example

```bash
$ args.check-number 2
$ alias alias2="alias1"
$ main.dereference-alias_ "github/vargiuscuola/std-lib.bash/main"
# return __="func1"
```

## args_parse()

Parse the command line options.
  It store the parsed options and remaining arguments to the provided variables.
  In addition to getopt syntax, the form `-n:,--name` is allowed, which means that the same option can be interchangebly provided in the form `-n <value>` and `--name <value>`.
  The code and functionalities is a mix of the following two github projects:
  * [reconquest/args](https://github.com/reconquest/args)
  * [reconquest/opts.bash](https://github.com/reconquest/opts.bash)

### Arguments

* **$1** (Hashname): Variable name of an associative array where to store the parsed options. If the character dash `-` is provided, the parsed options and arguments are printed in stdout
* **$2** (Arrayname): (Optional, only provided if first argument is not a dash `-`) Variable name of an array where to store the arguments
* **$3** (Number): (Optional) The minimum number of arguments (if $4 is provided), or the mandatory number or arguments (if $4 is not provided)
* **$4** (Number): (Optional) Maximum number of arguments
* **$5** (String): Literal `--`: used as a separator for the following arguments
* **...** (String): Options definition and arguments to parse separated by `--`

### Exit codes

* Standard

### Output on stdout

* Parsed options and arguments, only if `-` is passed as the first argument

### Example

```bash
# Example n. 1
$ declare -A opts ; declare -a args
$ args.parse opts args -- -av -b: -n:,--name -- -aav --name=somename arg1 arg2
$ declare -p opts
declare -A opts=([-v]="1" [-a]="2" [-n]="pippo" [--name]="pippo" )
$ declare -p args
declare -a args=([0]="arg1" [1]="arg2")
# Example n. 2
$ args.parse - -- -av -b: -n:,--name -- -aav --name=somename arg1 arg2
### args_parse
# Options:
-v 1
-a 2
-n somename
--name somename
# Arguments:
arg1
arg2
#- args_parse
# Example n. 3
$ args.parse opts args 2 3 -- -av -b: -n:,--name -- -aav --name=somename arg1
[ERROR] Wrong number of arguments: 1 instead of 2..3
```



# Internal Functions
* [:args_check-number()](#args_check-number)


## :args_check-number()

Validate the number of arguments, writing an error message and exiting if the check is not passed.  
  This is an helper function: don't use it directly, use `args_check-number` or his alias `args.check-number` instead.

### Arguments

* **$2** (Number): The minimum number of arguments (if $2 is provided), or the mandatory number or arguments (if $2 is not provided)
* **$3** (Number): (Optional) Maximum number of arguments: can be `-` if there is no limit on the number of maximum arguments


