# lock.sh

Provide locking functionalities.


# Overview

Although different precautions are put into practice to avoid inconsistencies due to concurrency, some operations are not atomic so this library is not concurrency safe.
Specifically, the lock creation is atomic, while the deletion or release mechanism is not.  
More appropriate tools for locking couldn't be used because I wanted it to be cross platform, working on Git for Windows as well as in Linux.  
Avoid to use it if your requirements expect a solid locking mechanism.  
Use the command `module.doc <function_name>` to see the documentation for a function (see documentation [here](https://github.com/vargiuscuola/std-lib.bash#examples))

# Settings

* **\_LOCK__KILL_PROCESS_WAIT** (Number)[default: **1**]: Seconds to wait for the killed process to terminate: the actual wait can double because a second signal KILL is sent if the first one TERM fail


# Global Variables

* **\_LOCK__RUN_DIR** (String): Run dir path


# Functions
* [lock_kill()](#lock_kill)
* [lock_release()](#lock_release)
* [lock_is-active()](#lock_is-active)
* [lock_cleanup()](#lock_cleanup)
* [lock_is-mine()](#lock_is-mine)
* [lock_list_()](#lock_list_)
* [lock_new()](#lock_new)


## lock_kill()

### Aliases

* **lock.kill**

### Arguments

* **$1** (String)[default: **Caller script name**]: An arbitrary lock name

### Exit codes

* **0**: Lock is removed and process holding it is already terminated or successfuly killed

### Exit codes

* **1**: Cannot kill the process holding to lock

### Exit codes

* **2**: Lock file cannot be deleted, but process that held is already terminated or successfully killed

## lock_release()

### Aliases

* **lock.release**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Exit codes

* **0**: Lock successfully released

### Exit codes

* **1**: Current process doesn't own the lock and cannot release it

### Exit codes

* **2**: Lock file cannot be deleted

## lock_is-active()

### Aliases

* **lock.is-active**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Exit codes

* **0**: Lock is active

### Exit codes

* **1**: Lock is expired (file lock not present)

### Exit codes

* **2**: Lock has been released because the associated process has already terminated

## lock_cleanup()

### Aliases

* **lock.cleanup**

### Exit codes

* **0**: One or more locks has been released

### Exit codes

* **1**: No locks has been released

### Return with global scalar $__, array $__a or hash $__h

* The number of locks released

## lock_is-mine()

### Aliases

* **lock.is-mine**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Exit codes

* $True (0) if lock is present and owned by the current process

## lock_list_()

### Aliases

* **lock.list_**

### Arguments

* **$1** (Number)[default: **PID of current process $BASHPID**]: Pid of the process for which determine the list of locks owned by it: if an empty argument is provided, all locks are returned regardless of owner

### Return with global scalar $__, array $__a or hash $__h

* Array of lock names owned by the specified process

## lock_new()

### Aliases

* **lock.new**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Arguments

* **$2** (String)[default: **0**]: If lock is busy, wait $2 amount of time: can be -1 (wait forever), 0 (don't wait) or a time format as in [datetime.interval-to-sec_()](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-main.md#datetime_interval-to-sec_)
* **$3** (String)[default: **-1**]: If lock is busy, release the lock terminating the process owning it if the lock is expired, i.e. if $3 amount of time is passed since the creation of the lock: can be -1 (the lock never expire), 0 (the lock expire immediately) or a time format as in [datetime.interval-to-sec_()](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-main.md#datetime_interval-to-sec_)

### Exit codes

* **0**: Got the lock

### Exit codes

* **1**: Lock is busy and is not expired

### Exit codes

* **2**: Lock is expired but was not possible to terminate the process owning it

### Exit codes

* **3**: Cannot obtain the lock for other reasons


