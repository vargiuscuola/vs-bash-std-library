# module.sh

Include shell libraries modules


# Overview

Allow loading of libraries modules which simply are script files containing libraries of functions organized in classes.  
A module can contain one or more classes, where a class is a set of homogeneous functions with names prefixed with the name of the class.  
For example, the module [main](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-main.md) contains classes as `array`, `hash` etc.,
with functions of class `array` starting with the prefix `array_`.  
For a module containing only one class, the name of the class is the name of the module, as in the module [trap](https://github.com/vargiuscuola/std-lib.bash/blob/master/REFERENCE-trap.md)
where all functions start with `trap_`.
Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))

# Global Variables

* **\_MODULE__CLASS_TO_PATH** (Hash): Associate each class defined in modules to the script's path containing it: it is set by the `module_import` function or his alias `module.import`
* **\_MODULE__IMPORTED_MODULES** (Array): Imported modules


# Functions
* [module_import()](#module_import)
* [module_get-class-path_()](#module_get-class-path_)
* [module_list-class-functions()](#module_list-class-functions)
* [module_list-classes()](#module_list-classes)
* [module_doc()](#module_doc)


## module_import()

### Aliases

* **module.import**

### Arguments

* **$1** (String): Module path. Shell extension `.sh` can be omitted

### Options

* **-f|--force**: Force the import of the module also if already imported

### Exit codes

* Standard

### Example

```bash
$ module.import github/vargiuscuola/std-lib.bash/main
$ module.import --force args
```

## module_get-class-path_()

### Aliases

* **module.get-class-path_**

### Arguments

* **$1** (String): Class name

### Return with global scalar $__, array $__a or hash $__h

* Path of the file where the class is defined (see the documentation of [module_import()](#module_import) for an explanation of the concept of class in this context).

### Example

```bash
$ cd /var/cache
$ module.abs-path_ "../lib"
# return __="/var/lib"
```

## module_list-class-functions()

### Aliases

* **module.list-class-functions**

### Arguments

* **$1** (String): Class name

### Output on stdout

* List of functions which are part of the provided class

### Example

```bash
$ module.list-class-functions args
args.check-number
args.parse
args_check-number
args_parse
args_to_str_
```

## module_list-classes()

### Aliases

* **module.list-classes**

### Arguments

* **$1** (String): Module name.

### Output on stdout

* List of classes defined in the provided module

### Example

```bash
$ module.list-classes main
hash
main
collection
datetime
list
shopt
array
```

## module_doc()

### Aliases

* **module.doc**

### Arguments

* **$1** (String): Function name

### Output on stdout

* Print the documentation for the function



# Internal Functions
* [:module_abs-path_()](#module_abs-path_)


## :module_abs-path_()

### Aliases

* **module.abs-path_**

### Arguments

* **$1** (String): Path

### Return with global scalar $__, array $__a or hash $__h

* Normalized absolute path

### Example

```bash
$ cd /var/cache
$ module.abs-path_ "../lib"
# return __="/var/lib"
```


