# package.sh

load shell libraries packages as git repositories

## Parameters

* **_PACKAGE__LIB_DIR** (string)[default: **/lib/sh in Linux - /c/linux-lib/sh in Windows**]: shell libraries base path


## Functions
* [package_get-lib-dir_()](#package_get-lib-dir_)
* [package_load()](#package_load)


### package_get-lib-dir_()

Print library base path

#### Example

```bash
package.get-lib-dir_
=> /lib/sh
```

_Function has no arguments._

#### Output on stdout

* Library path

### package_load()

Load required package, cloning the git repository hosting it

#### Example

```bash
package.load github.com/vargiuscuola/std-lib.bash
```

#### Arguments

* **$1** (string): Git repository url without scheme (https:// is used)

#### Exit codes

* **0**:  If successfull
* **>0**: On failure

#### Output on stdout

* Informative messages

#### Output on stderr

* Error messages


