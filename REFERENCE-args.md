# args.sh

Provide argument parsing functionalities

## Global Variables

* **\_ARGS__RED** (String): Red terminal color code
* **\_ARGS__YELLOW** (String): Yellow terminal color code
* **\_ARGS__CYAN** (String): Cyan terminal color code
* **\_ARGS__COLOR_OFF** (String): Terminal code to turn off color


## Functions
* [args_parse()](#args_parse)


### args_parse()

Parse the command line options.
  It store the parsed options and remaining arguments to the provided variables.
  Additionally to getopt syntax, it allows aliases provided in the following form:
  * -n:,--name
  which, in this case, means that the same option can be interchangebly provided in the form `-n <value>` and `--name <value>`.
  The code and functionalities is a mix of the following two github projects:
  * [reconquest/args](https://github.com/reconquest/args)
  * [reconquest/opts.bash](https://github.com/reconquest/opts.bash)

#### Aliases

* **args.parse**

#### Arguments

* **$1** (Hashname): Variable name of an associative array where to store the parsed options. If the character dash `-` is provided, the parsed options and arguments are printed in stdout
* **$2** (Arrayname): (Optional, only provided if first argument is not a dash `-`) Variable name of an array where to store the arguments
* **...** (Options): definition and options to parse separated by --

#### Exit codes

* Standard

#### Output on stdout

* Parsed options and arguments, only if `-` is passed as the first argument

#### Example

```bash
$ declare -A opts ; declare -a args
$ args.parse opts args -av -b: -n:,--name -- -aav --name=somename arg1 arg2
$ declare -p opts
declare -A opts=([-v]="1" [-a]="2" [-n]="pippo" [--name]="pippo" )
$ declare -p args
declare -a args=([0]="arg1" [1]="arg2")
$ args.parse - -av -b: -n:,--name -- -aav --name=somename arg1 arg2
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
```


