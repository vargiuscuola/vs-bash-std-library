# module.sh

Include shell libraries modules

# Global Variables

* **\_MODULE__CLASS_TO_PATH** (Hash): Associate each class defined in modules to the script's path containing it: it is set by the `module_import` function and his alias `module.import`
* **\_MODULE__IMPORTED_MODULES** (Array): Imported modules


# Functions
* [module_import()](#module_import)
* [module_get-class-path_()](#module_get-class-path_)
* [module_list-class-functions()](#module_list-class-functions)
* [module_list-classes()](#module_list-classes)


## module_import()

Import a module, i.e. a shell library path which is sourced by the current function.  
  The provided library path can be relative or absolute. If it's relative, the library will be searched in the following paths:
  * calling path
  * current path (where the current script reside)
  * default library path (/lib/sh in Linux or /c/linux-lib/sh in Windows)
  If the requested module is correctly `source`-ed, its path is added to the list of imported modules stored in global variable `_MODULE__IMPORTED_MODULES`.
  Also, the classes defined inside the module are linked to the path of the module through the associative array `_MODULE__CLASS_TO_PATH`: the classes contained inside a module are declared
  inside the module itself through the array _${capitalized module name}__CLASSES. If this variable is not defined, is expected that only one class is defined with the same name of the module.  
  For example, the module `github/vargiuscuola/std-lib.bash/args`, which doesn't declare the variable `_ARGS_CLASSES`, is supposed to define only one class named `args`.  
  The concept of class in this context refers to an homogeneous set of functions all starting with the same prefix `<class name>_` as in `args_check-number` and `args_parse`.

### Aliases

* **module.import**

### Arguments

* **$1** (String): Module path. Shell extension `.sh` can be omitted

### Exit codes

* Standard

### Example

```bash
$ module.import "github/vargiuscuola/std-lib.bash/main"
```

## module_get-class-path_()

Return the path of the provided class.

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

List the functions of the provided class, which must be already loaded with `module.import` or at least `source`-ed.

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

List the classes defined inside a module.

### Aliases

* **module.list-classes**

### Arguments

* **$1** (String): Module name.

### Output on stdout

* List of classes defined in the provided module

### Example

```bash
$ module.list-classes main
args.check-number
args.parse
args_check-number
args_parse
args_to_str_
```



# Internal Functions
* [:module_abs-path_()](#module_abs-path_)


## :module_abs-path_()

Return normalized absolute path.

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


