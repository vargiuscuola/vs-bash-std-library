# package.sh

Load shell libraries packages as git repositories

# Overview

Allow loading of shell libraries packages provided in git repositories with a simple command as `package.load github.com/vargiuscuola/shdoc`.
  
  Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))


# Settings

* **\_PACKAGE__LIB_DIR** (string)[default: **/lib/sh in Linux or /c/linux-lib/sh in Windows**]: shell libraries base path


# Functions
* [package_get-lib-dir_()](#package_get-lib-dir_)
* [package_get-path_()](#package_get-path_)
* [package_update()](#package_update)
* [package_check()](#package_check)
* [package_load()](#package_load)


## package_get-lib-dir_()

Return the library base path.

### Aliases

* **package.get-lib-dir_**

_Function has no arguments._

### Return with global scalar $__, array $__a or hash $__h

* Library dir path

### Example

```bash
$ package.get-lib-dir_
   return> /lib/sh
```

## package_get-path_()

Return the path of the provided package

### Aliases

* **package.get-path_**

### Arguments

* **$1** (String): Name of the package (in the form of a git repository url without scheme)

### Example

```bash
$ package_get-path_ github.com/vargiuscuola/std-lib.bash
# return __=/lib/sh/github.com/vargiuscuola/std-lib.bash
```

### Return with global scalar $__, array $__a or hash $__h

* Path of the provided package

## package_update()

Update a git package from the repository remote.

### Aliases

* **package.update**

### Arguments

* **$1** (String): Git repository url without scheme (https is used)

### Exit codes

* Standard

### Example

```bash
$ package.update github.com/vargiuscuola/std-lib.bash
```

## package_check()

Check the consistency state of a package (through a `git fsck` command on the related git repository).

### Aliases

* **package.check**

### Arguments

* **$1** (String): Git repository url without scheme (https is used)

### Exit codes

* Standard

### Example

```bash
$ package.check github.com/vargiuscuola/std-lib.bash
```

## package_load()

Load required package, cloning the git repository hosting it.

### Aliases

* **package.load**

### Arguments

* **$1** (String): Git repository url without scheme (https is used)

### Exit codes

* Standard

### Output on stdout

* Informative messages

### Output on stderr

* Error messages

### Example

```bash
$ package.load github.com/vargiuscuola/std-lib.bash
```


