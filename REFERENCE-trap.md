# trap.sh

Manage shell traps and provide stack trace functionalities.


# Overview

It provide two features: the management of trap handlers (with the support of multiple handlers per signal) and stack trace funtionalities for debugging purposes.  
The stack trace allow to set which functions to trace, giving an extensive report of the code execution including:
* current and previous line number
* current and previous command
* current function
* function stack
Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))

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
* [trap_has-handler()](#trap_has-handler)
* [trap_add-handler()](#trap_add-handler)
* [trap_enable-trace()](#trap_enable-trace)
* [trap_is-trace-enabled()](#trap_is-trace-enabled)
* [trap_add-error-handler()](#trap_add-error-handler)
* [trap_remove-handler()](#trap_remove-handler)
* [trap_show-handlers()](#trap_show-handlers)
* [func_not_to_be_traced()](#func_not_to_be_traced)
* [trap_suspend-trace()](#trap_suspend-trace)
* [trap_step-trace-add()](#trap_step-trace-add)
* [trap_step-trace-reset()](#trap_step-trace-reset)
* [trap_step-trace-list()](#trap_step-trace-list)
* [trap_step-trace-remove()](#trap_step-trace-remove)
* [trap_step-trace-start()](#trap_step-trace-start)
* [trap_step-trace-stop()](#trap_step-trace-stop)
* [trap_show-stack-trace()](#trap_show-stack-trace)


## trap_has-handler()

### Aliases

* **trap.has-handler**

### Arguments

* **$1** (String): Label of the handler

### Arguments

* **$2** (String): Signal to which the handler responds to

### Exit codes

* Boolean ($True or $False)

### Example

```bash
$ trap.has-handler LABEL TERM
```

## trap_add-handler()

### Aliases

* **trap.add-handler**

### Arguments

* **$1** (String): Descriptive label to associate to the added trap handler

### Arguments

* **$2** (String): Action code to be called on specified signals: can be shell code or function name

### Arguments

* **...** (String): Signals to trap

### Exit codes

* **0**: On success

### Exit codes

* **1**: If label of the new trap handler already exists (or of one of the new trap handlers, in case of multiple signals)

### Example

```bash
$ trap.add-handler LABEL "echo EXIT" TERM
```

## trap_enable-trace()

### Aliases

* **trap.enable-trace**

## trap_is-trace-enabled()

### Aliases

* **trap.is-trace-enabled**

## trap_add-error-handler()

### Aliases

* **trap.add-error-handler**

### Arguments

* **$1** (String): Label of the trap handler

### Arguments

* **$2** (String): Action code to call on EXIT signal: can be shell code or a function name

### Example

```bash
$ trap.add-error-handler CHECKERROR 'echo ERROR Command \"$_TRAP__CURRENT_COMMAND\" [line $_TRAP__LINENO] on function $_TRAP__CURRENT_FUNCTION\(\)'
$ trap.add-error-handler CHECKERR trap.show-stack-trace
```

## trap_remove-handler()

### Aliases

* **trap.remove-handler**

### Arguments

* **$1** (String): Label of the trap handler to delete (as used in [trap_add-handler()](#trap_add-handler))
* **$2** (String): Signal to which the trap handler is currently associated

### Example

```bash
$ trap.remove-handler LABEL TERM
```

## trap_show-handlers()

### Aliases

* **trap.show-handlers**

### Output on stdout

* List of trap handlers, with the following columns separated by tab: `signal`, `index`, `label`, `action code`

## func_not_to_be_traced()

### Aliases

* **trap.suspend-trace**

### Example

```bash
func_not_to_be_traced() {
## trap_suspend-trace()

  : trap_suspend-trace
  # the following commands and functions are not traced 
  func2
}
```

## trap_step-trace-add()

### Aliases

* **trap.step-trace-add**

### Arguments

* **...** (String): Function name or alias to function for which enable the stack trace, in `step into` or `step over` mode depending of the closest preceding option, respectively `--step-into` or `--step-over` (step into mode is used by default if no option is specified)

### Options

* **--step-into**: Enable the step into debug trace for the following functions

### Options

* **--step-over**: Enable the step over debug trace for the following functions

### Example

```bash
$ trap.step-trace-add func1    # Add func1 to the list of step into debug traced functions
$ trap.step-trace-add --step-over func1 func2 --step-into func3    # Add func1 and func2 to the list of step over debug traced functions, and func3 to the list of step into debug traced functions
```

## trap_step-trace-reset()

### Aliases

* **trap.step-trace-reset**

## trap_step-trace-list()

### Aliases

* **trap.step-trace-list**

### Example

```bash
$ trap.step-trace-add --step-into func1 --step-over func2 func3
$ trap.step-trace-list
step-into|func1
step-over|func2
step-over|func3
```

## trap_step-trace-remove()

### Aliases

* **trap.step-trace-remove**

### Arguments

* **...** (String): Function name or alias to function to remove from the step-trace enabled list. The function is removed from the `step into` or `step over` mode list depending of the closest preceding option, respectively `--step-into` or `--step-over` (step into mode is used by default if no option is specified)

### Options

* **--step-into**: Disable the step into debug trace for the following functions

### Options

* **--step-over**: Disable the step over debug trace for the following functions

### Example

```bash
$ trap.step-trace-add --step-over func1 func2 --step-into func3    # Add func1 and func2 to the list of step over debug traced functions, and func3 to the list of step into debug traced functions
$ trap.step-trace-remove --step-over func1              # Disable step trace for function func1
$ trap.step-trace-list
step-into|func3
step-over|func2
```

## trap_step-trace-start()

### Aliases

* **trap.step-trace-start**

## trap_step-trace-stop()

### Aliases

* **trap.step-trace-stop**

## trap_show-stack-trace()

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

### Aliases

* **trap.handler-helper**

### Arguments

* **$1** (String): Signal to handle

### Example

```bash
$ trap ":trap_handler-helper TERM" TERM
```


