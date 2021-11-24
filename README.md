# std-lib.bash

<p align="left">
  <a href="https://github.com/vargiuscuola/std-lib.bash"><img alt="vs-bash-std-library Actions Status" src="https://github.com/vargiuscuola/vs-bash-std-library/workflows/CI%20Workflow/badge.svg"></a>
</p>

Some bash libraries to manage and manipulate traps, locks, arguments, arrays, hashes, strings and others.
Functions are organized in the following modules:

* package.sh  
  Install a package of shell libraries contained in a git repository
* module.sh  
  Load a shell library module, which is simply a collection of functions.  
  A module can contain one or more classes, where a class is a set of homogeneous functions with names prefixed with the name of the class.  
  For example, the module `main` (described later) contains classes as `array`, `hash` etc., with functions of class `array` starting with the prefix `array_` and `array.` (the latter is used for aliases of `array_<function-name>` functions): see the naming conventions described below
* main.sh  
  Generic functions for manipulating arrays, hashes, strings, coloured messages and more
* trap.sh  
  Provide support for managing hooks functions to signals and debugger trace functionalities
* args.sh  
  A parser of command line options and arguments


## Installation

Clone the repository:

```bash
git clone git@github.com:vargiuscuola/std-lib.bash.git /lib/sh/std-lib.bash
```

and from your script load the library for managing modules `module.sh` and then import the required modules:

```bash
source "/lib/sh/std-lib.bash/module.sh"
module.import "std-lib.bash/main"
module.import "std-lib.bash/trap"
```

## Reference

* [main.sh](REFERENCE-main.md)
* [package.sh](REFERENCE-package.md)
* [module.sh](REFERENCE-module.md)
* [datatypes.sh](REFERENCE-datatypes.md)
* [std-lib.sh](REFERENCE-std-lib.md)
* [lock.sh](REFERENCE-lock.md)
* [info.sh](REFERENCE-info.md)
* [trap.sh](REFERENCE-trap.md)
* [args.sh](REFERENCE-args.md)

## Guidelines and conventions

### Return values

Most of the functions returning a value provide it through a global variable which `__` for a scalar value, `__a` for an array and `__h` for an associative array or hash: it is useful to prevent the calling script having to get the value through a subshell as in `ret=$( func )`.

The functions returning a value through a global variable end with an underscore `_`, such as in `array_find_`: see the [naming conventions](#naming-conventions) below.

### Naming conventions

A module can contain one or more classes, where a class is a set of homogeneous functions with names prefixed with the name of the class.
For example, the module `main` contains classes as `array`, `hash` etc., with functions of class `array` starting with the prefix `array_`, such as `array_find` and `array_include`.
For a module containing only one class, the name of the class is the name of the module, as in the module `trap.sh` where all functions start with `trap_`.

Usually for every function with a name `<class>_<function-name>` is defined an alias in the form `<class>.<function-name>`: so you can use both `array_find_` and `array.find_`.

A function name ends with an underscore `_` if it returns a value in a global variable (see the [Return values conventions](#return-values) above).
Sometimes alongside a function returning a value in a global variable, is defined a corresponding function with the same name apart the ending `_` and returning the value through the standard output (see for example `array_find_` and `array_find`).

The function name con contain a dash character `-`, such as in `datetime_interval-to-sec_`: I don't know if it's a good idea but so it is (I used to add an ending
`?` for the function returning a true/false value in the `ruby` style, but `bash` apparently ended supporting it).

### Performance optimizations

The libraries contained in this repository are performance wise: I would have preferred not to worry about it, and usually I don't do it with `bash` scripts, but I'm going to use them for a command completion library which needed to be responsive.

The general rules I followed are:

* return values in global variables if possible (see [Return values conventions](#return-values) above) to prevent the calling script having to get the value through a subshell
* use `bash` builtins whenever possible, such as regular expression substitutions with `${var/search/replace}` instead of piping to `sed`

I didn't test everything, but when I did it the aforementioned rules showed me a substantial improvement.

## Examples

Let's start loading the `main` module:

```bash
$ source "/lib/sh/std-lib.bash/module.sh"
$ module.import "std-lib.bash/main"
$ module.import "std-lib.bash/trap"
```

To see which classes are contained in a module:

```bash
$ module.list-classes main
main
array
hash
shopt
datetime
list
process
```

To list the functions included in a class:
```bash
$ module.list-class-functions hash
# Functions
hash_copy
hash_defined
hash_eq
hash_find-value_
hash_has-key
hash_init
hash_merge
# Aliases
hash.copy
hash.defined
hash.find-value_
hash.has-key
hash.init
hash.merge
hash.to_s
```

We want to see the documentation of a function, so we need to load the package `vargiuscuola/shdoc` from github:

```bash
$ source "/lib/sh/std-lib.bash/package.sh"
$ module.list-class-functions hash
package.load github.com/vargiuscuola/shdoc
```

which clone the repository to `/lib/sh/github.com/vargiuscuola/shdoc`.

Then we can see the documentation for every function (only function names, not aliases, I'm sorry):

```bash
$ module.doc hash_find-value_
## hash_find-value_()

Return the key of the hash which have the provided value.
[...]
```
