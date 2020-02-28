# lock.sh

Provide locking functionalities

## Environments Variables

* **\_LOCK__RUN_DIR** (String): Run dir path


## Functions
* [lock_kill()](#lock_kill)
* [lock_release()](#lock_release)
* [lock_new()](#lock_new)


### lock_kill()

Remove lock and kill associated process if present

#### Example

```bash
lock.kill <tag>
```

#### Arguments

* **$1** (string)[default: **Caller script name**]: Lock name

#### Exit codes

* **0**: Lock is removed and associated process is already terminated or successfuly killed
* **1**: Cannot kill process associated to lock
* **2**: Lock file cannot be deleted, but associated process is already terminated or successfully killed

### lock_release()

Release lock if current process own it

#### Example

```bash
lock.kill <tag>
```

#### Arguments

* **$1** (string)[default: **Caller script name**]: Lock name

#### Exit codes

* **0**: Lock successfully released
* **1**: Current process doesn't own the lock and cannot release it
* **2**: Lock file cannot be deleted

### lock_new()

Try to obtain a lock.
 If the lock 

#### Example

```bash
lock.new <tag>
```

#### Arguments

* **$1** (string)[default: **Caller script name**]: Lock name
* **$2** (string)[default: **Caller script name**]: Lock name

#### Exit codes

* **0**: Got the lock
* **1**: Lock is expired (file lock not present or associated process already terminated)


