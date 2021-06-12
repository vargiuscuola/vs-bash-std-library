# lock.sh

Provide locking functionalities.

# Settings

* **\_LOCK__KILL_PROCESS_WAIT1** (Number)[default: **0.1**]: Time to wait for the first check whether a process has been successfully killed
* **\_LOCK__KILL_PROCESS_WAIT2** (Number)[default: **0.5**]: Time to wait for the second check whether a process has been successfully killed 


# Global Variables

* **\_LOCK__RUN_DIR** (String): Run dir path


# Functions
* [lock_kill()](#lock_kill)
* [lock_release()](#lock_release)
* [lock_is-active()](#lock_is-active)
* [lock_is-mine()](#lock_is-mine)
* [lock_list_()](#lock_list_)
* [lock_new()](#lock_new)


## lock_kill()

Remove lock and kill associated process if present.  
  **This function is not concurrent safe.**

### Aliases

* **lock.kill**

### Arguments

* **$1** (String)[default: **Caller script name**]: An arbitrary lock name

### Exit codes

* **0**: Lock is removed and process holding it is already terminated or successfuly killed
* **1**: Cannot kill the process holding to lock
* **2**: Lock file cannot be deleted, but process that held is already terminated or successfully killed

## lock_release()

Release lock if current process own it.  
  **This function is not concurrent safe.**

### Aliases

* **lock.release**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Exit codes

* **0**: Lock successfully released
* **1**: Current process doesn't own the lock and cannot release it
* **2**: Lock file cannot be deleted

## lock_is-active()

Check if a lock is currently active, i.e. if file lock is present and the process holding it is still running.

### Aliases

* **lock.is-active**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Exit codes

* **0**: Lock is active
* **1**: Lock is expired (file lock not present or associated process already terminated)

## lock_is-mine()

Check if the current process is holding the provided lock.

### Aliases

* **lock.is-mine**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Exit codes

* $True (0) if lock is present and owned by the current process

## lock_list_()

List of locks owned by the current process of by the process with the provided pid.

### Aliases

* **lock.list_**

### Arguments

* **$1** (Number)[default: **PID of current process $BASHPID**]: Pid of the process for which determine the list of locks owned by it: if null, all locks are returned, regardless of owner

### Return with global scalar $__, array $__a or hash $__h

* Array of lock names owned by the specified process

## lock_new()

Try to obtain a lock.  
  **This function is not concurrent safe.**

### Aliases

* **lock.new**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name
* **$2** (String)[default: **0**]: If lock is busy, wait $2 amount of time: can be -1 (wait forever), 0 (don't wait) or a time format as in [datetime.interval-to-sec_()](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-main.md#datetime_interval-to-sec_)
* **$3** (String)[default: **-1**]: If lock is busy, release the lock terminating the process owning it if it the lock is expired, i.e. if $3 amount of time is passed since the creation of the lock: can be -1 (the lock never expire), 0 (the lock expire immediately) or a time format as in [datetime.interval-to-sec_()](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-main.md#datetime_interval-to-sec_)

### Exit codes

* **0**: Got the lock
* **1**: Lock is busy and is not expired
* **2**: Lock is expired but was not possible to terminate the process owning it
* **3**: Cannot obtain the lock for other reasons


