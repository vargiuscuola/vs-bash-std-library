# main.sh

Generic bash library functions (management of messages, traps, arrays, hashes, strings, etc.).

# Overview

Contains functions to manipulate different data types (strings, array and associative array) and common usage functions, such as some process
  management functions, shopt manipulation functions, dynamic regular expression manipulation functions and so on.  
  It contains the following classes:
    * main
    * array
    * hash
    * list
    * datetime
    * shopt
    * process
    * timer
  
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


# Settings

* **\_MAIN__KILL_PROCESS_WAIT_INTERVAL** (Number)[default: **0.1**]: Seconds to wait between checks to test whether a process has been successfully killed


# Global Variables

## Flags
* **\_MAIN__FLAGS\[SOURCED\]** (Bool): Is current file sourced? This flag is automatically set when the module is loaded
* **\_MAIN__FLAGS\[INTERACTIVE\]** (Bool): Is the current process running in an interactive shell? This flag is automatically set when the module is loaded
* **\_MAIN__FLAGS\[CHROOTED\]** (Bool): Is current process chrooted? This flag is set when calling `main.is-chroot()`
* **\_MAIN__FLAGS\[WINDOWS\]** (Bool): Is current O.S. Windows? This flag is set when calling `main.is-windows()`
## Boolean Values
* True 0
* False 1
## Others
* **\_MAIN__RAW_SCRIPTNAME** (String): Calling script path, raw and not normalized: as seen by the shell through BASH_SOURCE variable
* **\_MAIN__SCRIPTPATH** (String): Calling script path after any possible link resolution
* **\_MAIN__SCRIPTNAME** (String): Calling script real name (after any possible link resolution)
* **\_MAIN__SCRIPTDIR** (String): Absolute path where reside the calling script, after any possible link resolution
* **\_MAIN__GIT_PATH** (String): Root path of Git for Windows environment: it's set when calling `main.is-windows()`


# Functions
* [main_dereference-alias_()](#main_dereference-alias_)
* [main_is-windows()](#main_is-windows)
* [main_is-chroot()](#main_is-chroot)
* [main_set-script-path-info()](#main_set-script-path-info)
* [shopt_backup()](#shopt_backup)
* [shopt_restore()](#shopt_restore)
* [datetime_interval-to-sec_()](#datetime_interval-to-sec_)
* [timer_start()](#timer_start)
* [timer_elapsed()](#timer_elapsed)
* [array_find-indexes_()](#array_find-indexes_)
* [array_find_()](#array_find_)
* [array_include()](#array_include)
* [array_intersection_()](#array_intersection_)
* [array_remove-at()](#array_remove-at)
* [array_remove()](#array_remove)
* [array_remove-values()](#array_remove-values)
* [array_defined()](#array_defined)
* [array_init()](#array_init)
* [array_uniq_()](#array_uniq_)
* [array_eq()](#array_eq)
* [array_to_s()](#array_to_s)
* [set_eq()](#set_eq)
* [list_find_()](#list_find_)
* [list_include()](#list_include)
* [regexp_escape-bash-pattern_()](#regexp_escape-bash-pattern_)
* [regexp_escape-ext-regexp-pattern_()](#regexp_escape-ext-regexp-pattern_)
* [regexp_escape-regexp-replace_()](#regexp_escape-regexp-replace_)
* [string_append()](#string_append)
* [hash_defined()](#hash_defined)
* [hash_init()](#hash_init)
* [hash_has-key()](#hash_has-key)
* [hash_merge()](#hash_merge)
* [hash_copy()](#hash_copy)
* [hash_find-value_()](#hash_find-value_)
* [hash_eq()](#hash_eq)
* [fd_get_()](#fd_get_)
* [process_is-child()](#process_is-child)
* [process_kill()](#process_kill)
* [env_PATH_append-item()](#env_path_append-item)
* [env_PATH_prepend-item()](#env_path_prepend-item)


## main_dereference-alias_()

Dereference shell aliases: return the name of the function to which an alias point to, resolving it recursively if needed

### Arguments

* **$1** (String): Name of alias to dereference

### Return with global scalar $__, array $__a or hash $__h

* String Name of function to which provided alias point to

### Example

```bash
$ alias alias1="func1"
$ alias alias2="alias1"
$ main.dereference-alias_ alias2
# return __="func1"
```

## main_is-windows()

Check whether the current environment is Windows, testing if `uname -a` return a string starting with `MINGW`.  
  Store the result $True or $False in the flag _MAIN__FLAGS[WINDOWS].

### Aliases

* **main.is-windows**

### Example

```bash
$ uname -a
MINGW64_NT-6.1 chiller2 2.11.2(0.329/5/3) 2018-11-10 14:38 x86_64 Msys
$ main.is-windows
# statuscode = 0
```

## main_is-chroot()

Check whether the script is chroot'ed, and store the value $True or $False in flag $_MAIN__FLAGS[CHROOTED].

### Exit codes

* Standard (0 for true, 1 for false)

### Example

```bash
main.is-chroot
```

## main_set-script-path-info()

Set the current script path and the current script directory to the global variables `_MAIN__SCRIPTPATH` and `_MAIN__SCRIPTDIR`.

### Example

```bash
$ main.set-script-path-info
$ echo _MAIN__SCRIPTPATH=$_MAIN__SCRIPTPATH
_MAIN__SCRIPTPATH=/usr/local/src/script.sh
$ echo _MAIN__SCRIPTDIR=$_MAIN__SCRIPTDIR
_MAIN__SCRIPTDIR=/usr/local/src
```

## shopt_backup()

Backup the provided shopt options.

### Arguments

* **...** (String): Options to be backed up

### Example

```bash
$ shopt -p expand_aliases
shopt -s expand_aliases
$ shopt.backup expand_aliases extdebug
$ shopt -u expand_aliases
$ shopt -p expand_aliases
shopt -u expand_aliases
$ shopt.restore expand_aliases extdebug
$ shopt -p expand_aliases
shopt -s expand_aliases
```

## shopt_restore()

Restore the provided shopt options backuped up by the previously called `shopt.backup` function.

### Arguments

* **...** (String): Options to be restored

### Example

```bash
$ shopt -p expand_aliases
shopt -s expand_aliases
$ shopt.backup expand_aliases extdebug
$ shopt -u expand_aliases
$ shopt -p expand_aliases
shopt -u expand_aliases
$ shopt.restore expand_aliases extdebug
$ shopt -p expand_aliases
shopt -s expand_aliases
```

## datetime_interval-to-sec_()

Convert the provided time interval to a seconds interval. The format of the time interval is the following:  
  [\<n\>d] [\<n\>h] [\<n\>m] [\<n\>s]

### Arguments

* **...** (String): Any of the following time intervals: \<n\>d (\<n\> days), \<n\>h (\<n\> hours), \<n\>m (\<n\> minutes) and \<n\>s (\<n\> seconds)

### Example

```bash
$ datetime.interval-to-sec_ 1d 2h 3m 45s
# return __=93825
```

## timer_start()

Start a timer

### Arguments

* **$1** (String)[default: **\_**]: Name of timer

## timer_elapsed()

Return the seconds elapsed for the provided timer

### Arguments

* **$1** (String)[default: **\_**]: Name of timer

### Return with global scalar $__, array $__a or hash $__h

* Return the elapsed seconds for the timer

### Example

```bash
$ timer.start timer1
$ sleep 5
$ timer.elapsed timer1
# return __=5
```

## array_find-indexes_()

Return the list of array's indexes which have the provided value.

### Arguments

* **$1** (String): Array name
* **$2** (String): Value to find

### Return with global scalar $__, array $__a or hash $__h

* An array of indexes of the array containing the provided value.

### Exit codes

* 0 if at least one item in array is found, 1 otherwise

### Example

```bash
$ declare -a ary=(a b c "s 1" d e "s 1")
$ array.find-indexes_ ary "s 1"
# return __a=(3 6)
```

## array_find_()

Return the index of the array containing the provided value, or -1 if not found.

### Arguments

* **$1** (String): Array name
* **$2** (String): Value to find

### Return with global scalar $__, array $__a or hash $__h

* The index of the array containing the provided value, or -1 if not found.

### Exit codes

* 0 if found, 1 if not found

### Example

```bash
$ declare -a ary=(a b c "s 1" d e "s 1")
$ array.find_ ary "s 1"
# return __=3
```

## array_include()

Check whether an item is present in the provided array.

### Arguments

* **$1** (String): Array name
* **$2** (String): Value to find

### Exit codes

* 0 if found, 1 if not found

### Example

```bash
$ declare -a ary=(a b c "s 1" d e "s 1")
$ array.include ary "s 1"
# exitcode=0
```

## array_intersection_()

Return an array containing the intersection between two arrays.

### Arguments

* **$1** (String): First array name
* **$2** (String): Second array name

### Return with global scalar $__, array $__a or hash $__h

* An array containing the intersection of the two provided arrays.

### Exit codes

* 0 if the intersection contains at least one element, 1 otherwise

### Example

```bash
$ declare -a ary1=(a b c d e f)
$ declare -a ary2=(b d g h)
$ array.intersection_ ary1 ary2
# return __a=(b d)
```

## array_remove-at()

Remove the item at the provided index from array.

### Arguments

* **$1** (String): Array name
* **$2** (String): Index of the item to remove

### Example

```bash
$ declare -a ary=(a b c d e f)
$ array.remove-at ary 2
$ declare -p ary
declare -a ary=([0]="a" [1]="b" [2]="d" [3]="e" [4]="f")
```

## array_remove()

Remove the first instance of the provided item from array.

### Arguments

* **$1** (String): Array name
* **$2** (String): Item to remove

### Exit codes

* 0 if item is found and removed, 1 otherwise

### Example

```bash
$ declare -a ary=(a b c d e a)
$ array.remove ary a
$ declare -p ary
declare -a ary=([0]="b" [1]="c" [2]="d" [3]="e" [4]="a")
```

## array_remove-values()

Remove any occurrence of the provided item from array.

### Arguments

* **$1** (String): Array name
* **$2** (String): Item to remove

### Example

```bash
$ declare -a ary=(a b c d e a)
$ array.remove-values ary a
$ declare -p ary
declare -a ary=([0]="b" [1]="c" [2]="d" [3]="e")
```

## array_defined()

Check whether an array with the provided name exists.

### Arguments

* **$1** (String): Array name

### Exit codes

* Standard (0 for true, 1 for false)

## array_init()

Initialize an array (resetting it if already existing).

### Arguments

* **$1** (String): Array name

## array_uniq_()

Return an array with duplicates removed from the provided array.

### Arguments

* **$1** (String): Array name

### Return with global scalar $__, array $__a or hash $__h

* Array with duplicates removed

### Example

```bash
$ declare -a ary=(1 2 1 5 6 1 7 2)
$ array.uniq_ "${ary[@]}"
$ declare -p __a
declare -a __a=([0]="1" [1]="2" [2]="5" [3]="6" [4]="7")
```

## array_eq()

Compare two arrays

### Arguments

* **$1** (String): First array name
* **$2** (String): Second array name

### Exit codes

* 0 if the array are equal, 1 otherwise

### Example

```bash
$ declare -a ary1=(1 2 3)
$ declare -a ary2=(1 2 3)
$ array.eq ary1 ary2
# exitcode=0
```

## array_to_s()

Print a string with the definition of the provided array or hash (as shown in `declare -p` but without the first part declaring the variable).

### Aliases

* **hash.to_s**

### Arguments

* **$1** (String): Array name

### Example

```bash
$ declare -a ary=(1 2 3)
$ array.to_s ary
([0]="1" [1]="2" [2]="3")
```

## set_eq()

Compare two sets (a set is an array where index associated to values are negligibles)

### Arguments

* **$1** (String): First array name
* **$2** (String): Second array name

### Exit codes

* 0 if the values of arrays are the same, 1 otherwise

### Example

```bash
$ declare -a ary1=(1 2 3 1 1)
$ declare -a ary2=(3 2 1 2 2)
$ set.eq ary1 ary2
# exitcode=0
```

## list_find_()

Return the index inside a list in which appear the provided searched item.

### Aliases

* **list_include**
* **list.include**

### Arguments

* **$1** (String): Item to find
* **...** (String): Elements of the list

### Return with global scalar $__, array $__a or hash $__h

* The index inside the list in which appear the provided item.

### Exit codes

* 0 if the item is found, 1 otherwise

## list_include()

Check whether an item is included in a list of values.

### Arguments

* **$1** (String): Item to find
* **...** (String): Elements of the list

### Exit codes

* 0 if the item is found, 1 otherwise

## regexp_escape-bash-pattern_()

Escape a string which have to be used as a search pattern in a bash parameter expansion as ${parameter/pattern/string}.
 The escaped characters are `%*[?/`

### Arguments

* **$1** (String): String to be escaped

### Return with global scalar $__, array $__a or hash $__h

* Escaped string

### Example

```bash
$ regexp.escape-bash-pattern_ 'a * x #'
# return __=a \* x \#
```

## regexp_escape-ext-regexp-pattern_()

Escape a string which have to be used as a search pattern in a extended regexp in `sed` or `grep`.
  The escaped characters are the following: `{$.*[\^|]`.

### Arguments

* **$1** (String): String to be escaped
* **$2** (String)[default: **/**]: Separator used in the `sed` expression

### Return with global scalar $__, array $__a or hash $__h

* Escaped string

### Example

```bash
$ regexp.escape-ext-regexp-pattern_ "[WW]"  "W"
# return __=\[\W\W[]]
```

## regexp_escape-regexp-replace_()

Escape a string which have to be used as a replace string on a `sed` command.
  The escaped characters are the separator character and the following characters: `/&`.

### Arguments

* **$1** (String): String to be escaped
* **$2** (String)[default: **/**]: Separator used in the `sed` expression

### Return with global scalar $__, array $__a or hash $__h

* Escaped string

### Example

```bash
$ regexp.escape-regexp-replace_ "p/x"
# return __="p\/x"
$ regexp.escape-regexp-replace_ "x//" "x"
# return __="\x//"
```

## string_append()

Append a string to the content of the provided variable, optionally prefixing it with a separator if the variable is not empty.

### Aliases

* **string.concat**

### Arguments

* **$1** (String): Variable name
* **$2** (String): String to append
* **$3** (String)[default: **" "**]: Separator

### Options

* **-m|--multi-line**: Append the string to every line of the destination variable

### Return with global scalar $__, array $__a or hash $__h

* Concatenation of the two strings, optionally separated by the provided separator

## hash_defined()

Check whether an hash with the provided name exists.

### Arguments

* **$1** (String): Hash name

### Exit codes

* Standard (0 for true, 1 for false)

## hash_init()

Initialize an hash (resetting it if already existing).

### Arguments

* **$1** (String): Hash name

## hash_has-key()

Check whether a hash contains the provided key.

### Arguments

* **$1** (String): Hash name
* **$2** (String): Key name to find

### Exit codes

* Standard (0 for true, 1 for false)

## hash_merge()

Merge two hashes.

### Arguments

* **$1** (String): Variable name of the 1st hash, in which to merge the 2nd hash
* **$2** (String): Variable name of the 2nd hash, which is merged into the 1st hash

### Example

```bash
$ declare -A h1=([a]=1 [b]=2 [e]=3)
$ declare -A h2=([a]=5 [c]=6)
$ hash.merge h1 h2
$ declare -p h1
declare -A h1=([a]="5" [b]="2" [c]="6" [e]="3" )
```

## hash_copy()

Copy an hash.

### Arguments

* **$1** (String): Variable name of the hash to copy from
* **$2** (String): Variable name of the hash to copy to: if the hash is not yet defined, it will be created as a global hash

### Example

```bash
$ declare -A h1=([a]=1 [b]=2 [e]=3)
$ hash.copy h1 h2
$ declare -p h2
declare -A h2=([a]="1" [b]="2" [e]="3")
```

## hash_find-value_()

Return the key of the hash which have the provided value.

### Arguments

* **$1** (String): Hash name
* **$2** (String): Value to find

### Example

```bash
$ declare -A h1=([a]=1 [b]=2 [e]=3)
$ hash.find-value_ h1 2
$ echo $__
b
```

## hash_eq()

Compare two hashes

### Arguments

* **$1** (String): First hash name
* **$2** (String): Second hash name

### Exit codes

* 0 if the hashes are equal, 1 otherwise

### Example

```bash
$ declare -a h1=([key1]=val1 [key2]=val2)
$ declare -a h2=([key1]=val1 [key2]=val2)
$ hash.eq h1 h2
# exitcode=0
```

## fd_get_()

Get the first file descriptor number available.

_Function has no arguments._

### Return with global scalar $__, array $__a or hash $__h

* File descriptor number

## process_is-child()

Test if process with provided PID is a child of the current process.

### Arguments

* **$1** (Number): PID of the process

### Exit codes

* 0 if process is a child process, 1 otherwise

## process_kill()

Kill a process and wait for the process to actually terminate.

### Arguments

* **$1** (Number): PID of the process to kill
* **$2** (String)[default: **TERM**]: Signal to send
* **$2** (Number)[default: **3**]: Seconds to wait for the process to end: if zero, kill the process and return immediately

### Exit codes

* 0 if process is successfully killed, 1 otherwise (not killed or not ended before the timeout period)

## env_PATH_append-item()

Append the provided path to the `PATH` environment variable.

### Arguments

* **$1** (String): Path to append

## env_PATH_prepend-item()

Prepend the provided path to the `PATH` environment variable.

### Arguments

* **$1** (String): Path to prepend


