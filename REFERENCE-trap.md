# trap.sh

Manage shell traps

## Environments Variables

* **_TRAP__SIGNAL_HOOKS_<signal>** (Array):  List of hooks for signal <signal>


## Functions
* [trap_add-handler()](#trap_add-handler)


### trap_add-handler()

Add trap handler

#### Example

```bash
```

#### Arguments

* **$1** (string): Shell code or function to call on signal
* **...** (string): Signals to trap

#### Return with global $__ or $_\<MODULE\>__

* Index of 



## Internal Functions
* [:trap_handler-helper()](#trap_handler-helper)


### :trap_handler-helper()

Trap handler helper.
 It is supposed to be used as action in `trap` built-in bash command

#### Example

```bash
```

#### Arguments

* **$1** (string): Function to call
* **...** (string): Signals to trap

#### Return with global $__ or $_\<MODULE\>__

* 


