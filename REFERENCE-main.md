# main.sh

Generic bash library functions (management of messages, traps, arrays, hashes, strings, etc.)

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

## Flags
* **\_MAIN__FLAGS\[SOURCED\]** (Bool): Is current file sourced?
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
* [array_find-indexes_()](#array_find-indexes_)
* [array_find_()](#array_find_)
* [array_include()](#array_include)
* [array_intersection_()](#array_intersection_)
* [array_remove-at()](#array_remove-at)
* [array_remove()](#array_remove)
* [array_remove-values()](#array_remove-values)
* [array_defined()](#array_defined)
* [array_init()](#array_init)
* [array_unique_()](#array_unique_)
* [list_find_()](#list_find_)
* [list_include()](#list_include)
* [regexp_escape-bash-pattern_()](#regexp_escape-bash-pattern_)
* [regexp_escape-ext-regexp-pattern_()](#regexp_escape-ext-regexp-pattern_)
* [string_append()](#string_append)
* [hash_defined()](#hash_defined)
* [hash_init()](#hash_init)
* [hash_has-key()](#hash_has-key)
* [hash_merge()](#hash_merge)
* [hash_copy()](#hash_copy)
* [hash_find-value_()](#hash_find-value_)
* [fd_get_()](#fd_get_)
* [env_PATH_append-item()](#env_path_append-item)
* [env_PATH_prepend-item()](#env_path_prepend-item)
* [get_ext_color()](#get_ext_color)


## main_dereference-alias_()

Dereference shell aliases: return the name of the function to which an alias point to, resolving it recursively if needed

### Aliases

* **main.dereference-alias_**

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

### Exit codes

* Standard (0 for true, 1 for false)

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

### Aliases

* **main.is-chroot**

### Exit codes

* Standard (0 for true, 1 for false)

### Example

```bash
main.is-chroot
```

## main_set-script-path-info()

Set the current script path and the current script directory to the global variables `_MAIN__SCRIPTPATH` and `_MAIN__SCRIPTDIR`.

### Aliases

* **main.set-script-path-info**

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

### Aliases

* **shopt.backup**

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

### Aliases

* **shopt.restore**

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

### Aliases

* **datetime.interval-to-sec_**

### Arguments

* **...** (String): Any of the following time intervals: \<n\>d (\<n\> days), \<n\>h (\<n\> hours), \<n\>m (\<n\> minutes) and \<n\>s (\<n\> seconds)

### Example

```bash
$ datetime.interval-to-sec_ 1d 2h 3m 45s
# return __=93825
```

## array_find-indexes_()

Return the list of array's indexes which have the provided value.

### Aliases

* **array.find-indexes_**

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

### Aliases

* **array.find_**

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

### Aliases

* **array.include**

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

### Aliases

* **array.intersection_**

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

### Aliases

* **array.remove-at**

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

### Aliases

* **array.remove**

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

### Aliases

* **array.remove-values**

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

### Aliases

* **array.defined**

### Arguments

* **$1** (String): Array name

### Exit codes

* Standard (0 for true, 1 for false)

## array_init()

Initialize an array (resetting it if already existing).

### Aliases

* **array.init**

### Arguments

* **$1** (String): Array name

## array_unique_()

Return an array with duplicates removed from the provided array.

### Aliases

* **array.unique_**

### Arguments

* **$1** (String): Array name

### Return with global scalar $__, array $__a or hash $__h

* Array with duplicates removed

## list_find_()

Return the index inside a list in which appear the provided searched item.

### Aliases

* **list.find_**
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

### Aliases

* **list.include**

### Arguments

* **$1** (String): Item to find
* **...** (String): Elements of the list

### Exit codes

* 0 if the item is found, 1 otherwise

## regexp_escape-bash-pattern_()

Escape a string which have to be used as a search pattern in a bash parameter expansion as ${parameter/pattern/string}.

### Aliases

* **regexp.escape-bash-pattern_**

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

### Aliases

* **regexp.escape-ext-regexp-pattern_**

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

## string_append()

Append a string to the content of the provided variable, optionally prefixing it with a separator if the variable is not empty.

### Aliases

* **string.append**
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

### Aliases

* **hash.defined**

### Arguments

* **$1** (String): Hash name

### Exit codes

* Standard (0 for true, 1 for false)

## hash_init()

Initialize an hash (resetting it if already existing).

### Aliases

* **hash.init**

### Arguments

* **$1** (String): Hash name

## hash_has-key()

Check whether a hash contains the provided key.

### Aliases

* **hash.has-key**

### Arguments

* **$1** (String): Hash name
* **$2** (String): Key name to find

### Exit codes

* Standard (0 for true, 1 for false)

## hash_merge()

Merge two hashes.

### Aliases

* **hash.merge**

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

### Aliases

* **hash.copy**

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

### Aliases

* **hash.find-value_**

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

## fd_get_()

Get the first file descriptor number available.

### Aliases

* **hfd.get_**

_Function has no arguments._

### Return with global scalar $__, array $__a or hash $__h

* File descriptor number

## env_PATH_append-item()

Append the provided path to the `PATH` environment variable.

### Aliases

* **env.PATH.append-item**

### Arguments

* **$1** (String): Path to append

## env_PATH_prepend-item()

Prepend the provided path to the `PATH` environment variable.

### Aliases

* **env.PATH.prepend-item**

### Arguments

* **$1** (String): Path to prepend

## get_ext_color()

Get extended terminal color codes

### Arguments

* **$1** (number): Foreground color
* **$2** (number): Background color

### Example

```bash
get_ext_color 208
  => \e[38;5;208m
```

### Exit codes

* n.a.

### Output on stdout

* Color code.


