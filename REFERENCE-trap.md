# trap.sh

Manage shell traps

## Global Variables

* **\_TRAP__HOOKS_LIST_\<signal\>** (Array): List of hooks for signal \<signal\>
* **\_TRAP__HOOKS_DISABLED_\<signal\>** (Array): Keep track of disable hooks for signal \<signal\>
* **\_TRAP__HOOKS_LABEL_TO_CODE_\<signal\>** (Hash): Map label of hook to action code for signal \<signal\>
* **\_TRAP__FUNCTION_HANDLER_CODE** (String): Action to execute for every execution of any function (see function trap.set-function-handler)


## Functions
* [trap_add-handler()](#trap_add-handler)
* [trap_set-function-handler()](#trap_set-function-handler)


### trap_add-handler()

Add trap handler.
  It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__HOOKS_LIST_<signal>`.

#### Aliases

* **trap.add-handler**

#### Arguments

* **$1** (String): Action to call on specified signals: can be shell code or function name
* **...** (String): Signals to trap

#### Example

```bash
trap.add-handler "echo EXIT" TERM
```

### trap_set-function-handler()

Set an handler for every execution of any function.

#### Aliases

* **trap.set-function-handler**

#### Arguments

* **$1** (String): Signal to handle

#### Example

```bash
trap.set-function-handler ""
```



## Internal Functions
* [:trap_handler-helper()](#trap_handler-helper)


### :trap_handler-helper()

Trap handler helper.
  It is supposed to be used as the action in `trap` built-in bash command.

#### Aliases

* **trap.handler-helper**

#### Arguments

* **$1** (String): Signal to handle

#### Example

```bash
trap ":trap_handler-helper TERM" TERM
```


