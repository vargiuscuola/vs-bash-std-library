# trap.sh

Manage shell traps

## Environments Variables

* **_TRAP__SIGNAL_HOOKS_\<signal\>** (Array):  List of hooks for signal \<signal\>


## Functions
* [trap_add-handler()](#trap_add-handler)


### trap_add-handler()

Add trap handler.
 It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__SIGNAL_HOOKS_<signal>`.

#### Example

```bash
```

#### Arguments

* **$1** (string): Action to call on specified signals: can be shell code or function name
* **...** (string): Signals to trap

#### Return with global $__ or $_\<MODULE\>__

* Index of current handler inside the array of handlers for the specified signal



## Internal Functions
* [:trap_handler-helper()](#trap_handler-helper)


### :trap_handler-helper()

Trap handler helper.
 It is supposed to be used as action in `trap` built-in bash command

#### Example

```bash
```

#### Arguments

* **$1** (string): Signal to handle


