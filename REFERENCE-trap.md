# trap.sh

Manage shell traps

# Global Variables

* **\_TRAP__HOOKS_LIST_\<signal\>** (Array): List of hooks for signal \<signal\>
* **\_TRAP__HOOKS_LABEL_TO_CODE_\<signal\>** (Hash): Map label of hook to action code for signal \<signal\>
* **\_TRAP__FUNCTION_HANDLER_CODE** (String): Action to execute for every execution of any function (see function trap.set-function-handler)
* **\_TRAP__FUNCTION_NAME** (String): Name of the current function executed, set if a function handler is enabled through the `trap.set-function-handler` function
* **\_TRAP__CURRENT_COMMAND** (String): Laso command executed: available when command trace is enabled through `trap.enable-trace` function
* **\_TRAP__LAST_COMMAND** (String): Previous command executed: available when command trace is enabled through `trap.enable-trace` function
* **\_TRAP__TEMP_LINENO** (Number): Temporary line number, assigned to $_TRAP__LAST_LINENO only when needed
* **\_TRAP__LINENO** (Number): Line number of current command: available when command trace is enabled through `trap.enable-trace` function
* **\_TRAP__LAST_LINENO** (Number): Line number of previous command: available when command trace is enabled through `trap.enable-trace` function
* **\_TRAP__EXITCODE_\<signal\>** (Number): Exit code received by the trap handler for signal \<signal\>
* **\_TRAP__SUSPEND_COMMAND_TRACE** (String): The name of the function for which to suspend the debugger trace functionality (set by the use of the special syntax `: trap_suspend-trace`)
* **\_TRAP__SUSPEND_COMMAND_TRACE_IDX** (Number): The position inside the stack trace of the suspended function stored in the global variable `_TRAP__SUSPEND_COMMAND_TRACE`
* **\_TRAP__FUNCTION_STACK** (Array): An array of functions storing the stack trace
* **\_TRAP__LINENO_STACK** (Array): An array of numbers storing the line numbers inside each function in the stack trace respectively
* **\_TRAP__STEP_INTO_FUNCTIONS** (String): The name of the function inside which activate a debugging trace with a step into logic (set by the functions `trap.step-trace-add`, `trap.step-trace-remove` and `trap.step-trace-reset`)
* **\_TRAP__STEP_OVER_FUNCTIONS** (String): The name of the function inside which activate a debugging trace with a step over logic (set by the functions `trap.step-trace-add`, `trap.step-trace-remove` and `trap.step-trace-reset`)


# Functions
* [trap_add-handler()](#trap_add-handler)
* [trap_enable-trace()](#trap_enable-trace)
* [trap_add-error-handler()](#trap_add-error-handler)
* [trap_remove-handler()](#trap_remove-handler)
* [trap_show-handlers()](#trap_show-handlers)
* [trap_show-stack-trace()](#trap_show-stack-trace)


## trap_add-handler()

Add trap handler.
  It is possible to call this function multiple times for the same signal, which will generate an array of handlers for that signal stored in array `_TRAP__HOOKS_LIST_<signal>`.

### Aliases

* **trap.add-handler**

### Arguments

* **$1** (String): Descriptive label to associate to the added trap handler
* **$2** (String): Action code to call on specified signals: can be shell code or function name
* **...** (String): Signals to trap

### Exit codes

* **0**: On success
* **1**: If label of the new trap handler already exists (or of one of the new trap handlers, in case of multiple signals)

### Example

```bash
trap.add-handler LABEL "echo EXIT" TERM
```

## trap_enable-trace()

Enable command tracing by setting a trap on signal `DEBUG` that set the global variables $_TRAP__LAST_COMMAND, $_TRAP__CURRENT_COMMAND and $_TRAP__LINENO.

### Aliases

* **trap.enable-trace**

## trap_add-error-handler()

Add an error handler called on EXIT signal.
  To force the exit on command fail, the shell option `-e` is enabled. The ERR signal is not used instead because it doesn't allow to catch failing commands inside functions.

### Aliases

* **trap.add-error-handler**

### Arguments

* **$1** (String): Label of the trap handler
* **$2** (String): Action code to call on EXIT signal: can be shell code or a function name

### Example

```bash
trap.add-error-handler CHECKERROR 'echo ERROR Command \"$_TRAP__CURRENT_COMMAND\" [line $_TRAP__LINENO] on function $_TRAP__FUNCTION_NAME\(\)'
trap.add-error-handler CHECKERR trap.show-error
```

## trap_remove-handler()

Remove trap handler.

### Aliases

* **trap.remove-handler**

### Arguments

* **$1** (String): Label of the trap handler to delete (as used in `trap.add-handler` function)
* **$2** (String): Signal to which the trap handler is currently associated

### Example

```bash
trap.remove-handler LABEL TERM
```

## trap_show-handlers()

Show all trap handlers.

### Aliases

* **trap.show-handlers**

### Output on stdout

* List of trap handlers, with the following columns separated by tab: `signal`, `index`, `label`, `action code`

## trap_show-stack-trace()

Show error information.

### Aliases

* **trap.show-stack-trace**

### Arguments

* **$1** (Number)[default: **$_TRAP__EXITCODE_EXIT**]: Exit code: defaults to the exit code of EXIT trap handler

### Example

```bash
trap.add-error-handler CHECKERR trap.show-stack-trace
```



# Internal Functions
* [:trap_handler-helper()](#trap_handler-helper)


## :trap_handler-helper()

Trap handler helper.
  It is supposed to be used as the action in `trap` built-in bash command.

### Aliases

* **trap.handler-helper**

### Arguments

* **$1** (String): Signal to handle

### Example

```bash
trap ":trap_handler-helper TERM" TERM
```


