# trap.sh

Manage shell traps

## Environments Variables

* **\_TRAP__HOOKS_LIST_\<signal\>** (Array): List of hooks for signal \<signal\>
* **\_TRAP__HOOKS_DISABLED_\<signal\>** (Array): Keep track of disable hooks for signal \<signal\>


## Functions
* [trap_add-handler()](#trap_add-handler)
* [trap_disable-handler()](#trap_disable-handler)


### trap_add-handler()

Add trap handler.
  It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__HOOKS_LIST_<signal>`.

#### Example

```bash
trap.add-handler "echo EXIT" TERM
```

#### Arguments

* **$1** (String): Action to call on specified signals: can be shell code or function name
* **...** (String): Signals to trap

#### Return with global $__ or $_\<MODULE\>__

* Index of current handler inside the array of handlers for the specified signal: only relevant when providing a single signal

### trap_disable-handler()

Disable trap handler with the provided index.
  Note the the handler is not removed from the stack but only disable, avoiding the renumbering of following handlers and allowing to disable multiple handlers without hassle.

#### Example

```bash
trap.add-handler "echo handler1" EXIT
idx=$_TRAP__
trap.add-handler "echo handler2" EXIT
trap.disable-handler $_TRAP__
  onexit> is executed only handler2
```

#### Arguments

* **$1** (String): Signal which the handler to disable respond to
* **$2** (Int): Index of the handler to disable

#### Exit codes

* Standard



## Internal Functions
* [:trap_handler-helper()](#trap_handler-helper)


### :trap_handler-helper()

Trap handler helper.
  It is supposed to be used as the action in `trap` built-in bash command.

#### Example

```bash
trap ":trap_handler-helper TERM" TERM
```

#### Arguments

* **$1** (String): Signal to handle


