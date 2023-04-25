# main.sh

Generic bash library functions for managing shell options (`shopt`), timers, processes and file descriptors.

# Overview

Contains common usage functions, such as some process, shopt, file descriptor and timer management.  
  It contains the following classes:
  * main
  * shopt
  * process
  * env
  * fd
  * timer
  * flag
  
  Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))


# Settings

* **\_MAIN__KILL_PROCESS_WAIT_INTERVAL** (Number)[default: **0.1**]: Seconds to wait between checks to test whether a process has been successfully killed


# Global Variables

## _SETTINGS__HASH - Associative array used to store boolean values
* **\_SETTINGS__HASH\[SOURCED\]** (Bool): Is current file sourced? This flag is automatically set when the module is loaded
* **\_SETTINGS__HASH\[PIPED\]** (Bool): Is current file piped to another command? This flag is automatically set when the module is loaded
* **\_SETTINGS__HASH\[INTERACTIVE\]** (Bool): Is the current process running in an interactive shell? This flag is automatically set when the module is loaded
* **\_SETTINGS__HASH\[CHROOTED\]** (Bool): Is current process chrooted? This flag is set when calling `main.is-chroot()`
* **\_SETTINGS__HASH\[WINDOWS\]** (Bool): Is current O.S. Windows? This flag is set when calling `main.is-windows()`
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
* [main_is-piped()](#main_is-piped)
* [shopt_backup()](#shopt_backup)
* [shopt_restore()](#shopt_restore)
* [timer_start()](#timer_start)
* [timer_elapsed()](#timer_elapsed)
* [fd_get_()](#fd_get_)
* [process_is-child()](#process_is-child)
* [process_kill()](#process_kill)
* [env_PATH_append-item()](#env_path_append-item)
* [env_PATH_prepend-item()](#env_path_prepend-item)
* [file_mkfifo_()](#file_mkfifo_)
* [command_stdout_()](#command_stdout_)
* [var_assign()](#var_assign)
* [settings_is-enabled()](#settings_is-enabled)
* [settings_is-disabled()](#settings_is-disabled)
* [settings_enable()](#settings_enable)
* [settings_disable()](#settings_disable)
* [settings_set()](#settings_set)
* [settings_get_()](#settings_get_)


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
  Store the result $True or $False in the flag _SETTINGS__HASH[WINDOWS].

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

Check whether the script is chroot'ed, and store the value $True or $False in flag $_SETTINGS__HASH[CHROOTED].

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

## main_is-piped()

Check if the script is piped.

### Aliases

* **main.is-piped**

### Exit codes

* Standard (0 for true, 1 for false)

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

## timer_start()

Start a timer

### Aliases

* **timer.start**

### Arguments

* **$1** (String)[default: **\_**]: Name of timer

## timer_elapsed()

Return the seconds elapsed for the provided timer

### Aliases

* **timer.elapsed**

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

## fd_get_()

Get the first file descriptor number available.

### Aliases

* **hfd.get_**

_Function has no arguments._

### Return with global scalar $__, array $__a or hash $__h

* File descriptor number

## process_is-child()

Test if process with provided PID is a child of the current process.

Check if a process with provided PID exists.

### Aliases

* **process.exists**

### Arguments

* **$1** (Number): PID of the process

### Exit codes

* 0 if process exists, 1 otherwise

### Aliases

* **process.is-child**

### Arguments

* **$1** (Number): PID of the process

### Exit codes

* 0 if process is a child process, 1 otherwise

## process_kill()

Kill a process and wait for the process to actually terminate.

### Aliases

* **process.kill**

### Arguments

* **$1** (Number): PID of the process to kill
* **$2** (String)[default: **TERM**]: Signal to send
* **$2** (Number)[default: **3**]: Seconds to wait for the process to end: if zero, kill the process and return immediately

### Exit codes

* 0 if process is successfully killed, 1 otherwise (not killed or not ended before the timeout period)

## env_PATH_append-item()

Append the provided path to the `PATH` environment variable if not yet present.

### Aliases

* **env.PATH.append-item**

### Arguments

* **$1** (String): Path to append

## env_PATH_prepend-item()

Prepend the provided path to the `PATH` environment variable if not yet present.

### Aliases

* **env.PATH.prepend-item**

### Arguments

* **$1** (String): Path to prepend

## file_mkfifo_()

Create a `fifo` in shared memory (`/dev/shm`) and return his path

### Aliases

* **file.mkfifo_**

### Return with global scalar $__, array $__a or hash $__h

* The path of the newly create `fifo`

## command_stdout_()

Execute a command and return the first line of his standard output (or an empty string if no output is present).
  It use a `fifo` and appropriate redirection to get the standard output of the command without using a subshell (see this [Stackoverflow answer](https://stackoverflow.com/a/21636953/3821238)).

### Aliases

* **command.stdout_**

### Arguments

* **...** (String): Command to execute

### Exit codes

* The status code of the executed command

### Return with global scalar $__, array $__a or hash $__h

* The standard output of the provided command

## var_assign()

Execute a command and store the first line of his standard output (or an empty string if no output is present) to the provided variable name.
  It use a `fifo` and appropriate redirection to get the standard output of the command without using a subshell (see this [Stackoverflow answer](https://stackoverflow.com/a/21636953/3821238)).

### Aliases

* **var.assign**

### Arguments

* **$1** (String): Variable name where to store the standard output
* **...** (String): Command to execute

### Exit codes

* The status code of the executed command

## settings_is-enabled()

Return true if the provided setting is enabled

### Aliases

* **settings.is-enabled**

### Arguments

* **$1** (String): The setting name to check

### Exit codes

* Standard (0 for true, 1 for false)

### Example

```bash
$ settings.is-enabled TEST
# exitcode=1
$ settings.enable TEST
$ settings.is-enabled TEST && echo ENABLED
ENABLED
```

## settings_is-disabled()

Return true if the provided setting is disabled.
  The function only test if the setting has been explicitly disabled: testing a setting not being defined will return false.

### Aliases

* **settings.is-disabled**

### Arguments

* **$1** (String): The setting name to check

### Exit codes

* Standard (0 for true, 1 for false)

### Example

```bash
$ settings.is-disabled TEST
# exitcode=1
$ settings.enable TEST
$ settings.is-disabled TEST
# exitcode=1
$ settings.disable TEST
$ settings.is-disabled TEST && echo DISABLED
DISABLED
```

## settings_enable()

Enable the provided setting.

### Aliases

* **settings.enable**

### Arguments

* **$1** (String): The setting to enable

### Example

```bash
$ settings.is-enabled TEST
# exitcode=1
$ settings.enable TEST
$ settings.is-enabled TEST && echo ENABLED
ENABLED
```

## settings_disable()

Disable the provided setting.

### Aliases

* **settings.disable**

### Arguments

* **$1** (String): The setting to disable

### Example

```bash
$ settings.is-disabled TEST
# exitcode=1
$ settings.disable TEST
$ settings.is-disabled TEST && echo DISABLED
DISABLED
```

## settings_set()

Set the value of a setting.

### Aliases

* **settings.set**

### Arguments

* **$1** (String): The setting to set
* **$2** (String): The value to set

### Example

```bash
$ settings.set COLOR Red
$ settings.get_ COLOR
# return __="Red"
```

## settings_get_()

Get the value of a setting.

### Aliases

* **settings.get_**

### Arguments

* **$1** (String): The setting from which to retrieve the value

### Example

```bash
$ settings.set COLOR Red
$ settings.get_ COLOR
# return __="Red"
```


