# lock.sh

Provide locking functionalities

# Settings

* **\_LOCK__KILL_PROCESS_WAIT1** (Number)[default: **0.1**]: Time to wait for the first check if successfully killed a process
* **\_LOCK__KILL_PROCESS_WAIT2** (Number)[default: **0.5**]: Time to wait for the second check if successfully killed a process 


# Global Variables

* **\_LOCK__RUN_DIR** (String): Run dir path


# Functions
* [lock_kill()](#lock_kill)
* [lock_release()](#lock_release)
* [lock_list_()](#lock_list_)
* [lock_new()](#lock_new)


## lock_kill()

Remove lock and kill associated process if present

### Aliases

* **lock.kill**

### Arguments

* **$1** (String)[default: **Caller script name**]: An arbitrary lock name

### Exit codes

* **0**: Lock is removed and associated process is already terminated or successfuly killed
* **1**: Cannot kill process associated to lock
* **2**: Lock file cannot be deleted, but associated process is already terminated or successfully killed

## lock_release()

Release lock if current process own it

### Aliases

* **lock.release**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name

### Exit codes

* **0**: Lock successfully released
* **1**: Current process doesn't own the lock and cannot release it
* **2**: Lock file cannot be deleted

## lock_list_()

List of locks owned by the current process of by the process with the provided pid

### Aliases

* **lock.list_**

### Arguments

* **$1** (Number)[default: **PID of current process $$**]: Pid of the process for which determine the list of locks owned by it: if empty, all locks are returned, regardless of owner

### Return with global scalar $__, array $__a or hash $__h

* Array of lock names owned by the specified process

## lock_new()

Try to obtain a lock.

### Aliases

* **lock.new**

### Arguments

* **$1** (String)[default: **Caller script name**]: Lock name
* **$2** (String)[default: **0**]: If lock is busy, wait $2 amount of time: can be -1 (wait forever), 0 (don't wait) or a time format as described here (**needed link**)
* **$3** (String)[default: **-1**]: If lock is busy, release the lock terminating the process owning it if it the lock is expired, i.e. if $3 amount of time is passed since the creation of the lock: can be -1 (the lock never expire), 0 (the lock expire immediately) or a time format as described here (**needed link**)

### Exit codes

* **0**: Got the lock
* **1**: Lock is busy and is not expired
* **2**: Lock is expired but was not possible to terminate the process owning it
* **3**: Cannot obtain the lock for other reasons


