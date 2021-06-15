# module.sh

Include shell libraries modules


# Overview

Return normalized absolute path.

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


