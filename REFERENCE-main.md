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
* **\_MAIN__FLAGS\[CHROOTED\]** (Bool): Is current process chrooted? This flag is set when calling `main.is-chroot?()`
* **\_MAIN__FLAGS\[WINDOWS\]** (Bool): Is current O.S. Windows? This flag is set when calling `main.is-windows?()`
## Boolean Values
* True 0
* False 1
## Others
* **\_MAIN__RAW_SCRIPTNAME** (String): Calling script path, raw and not normalized: as seen by the shell through BASH_SOURCE variable
* **\_MAIN__SCRIPTPATH** (String): Calling script path after any possible link resolution
* **\_MAIN__SCRIPTNAME** (String): Calling script real name (after any possible link resolution)
* **\_MAIN__SCRIPTDIR** (String): Absolute path where reside the calling script, after any possible link resolution
* **\_MAIN__GIT_PATH** (String): Root path of Git for Windows environment: it's set when calling `main.is-windows?()`
* **\_MAIN__WINUTILS_PATH** (String): Path to the `win-utils` directory: it's set when calling `main.is-windows?()`


# Functions
* [main_dereference-alias_()](#main_dereference-alias_)
* [shopt_backup()](#shopt_backup)
* [shopt_restore()](#shopt_restore)
* [main_set-script-path-info()](#main_set-script-path-info)
* [datetime_interval-to-sec_()](#datetime_interval-to-sec_)
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
$ main.dereference-alias_ "github/vargiuscuola/std-lib.bash/main"
# return __="func1"
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

## datetime_interval-to-sec_()

Convert the provided time interval to a seconds interval. The format of the time interval is the following:  
  [<n>d] [<n>h] [<n>m] [<n>s]

### Aliases

* **datetime.interval-to-sec_**

### Arguments

* **...** (String): Any of the following time intervals: <n>d (<n> days), <n>h (<n> hours), <n>m (<n> minutes) and <n>s (<n> seconds)

### Example

```bash
$ datetime.interval-to-sec_ 1d 2h 3m 45s
# return __=93825
```

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


