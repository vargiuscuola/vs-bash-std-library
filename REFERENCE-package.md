# package.sh

Load shell libraries packages as git repositories

## Parameters

* **_PACKAGE__LIB_DIR** (string)[default: **/lib/sh in Linux or /c/linux-lib/sh in Windows**]: shell libraries base path


## Functions
* [package_get-lib-dir_()](#package_get-lib-dir_)
* [package_load()](#package_load)


### package_get-lib-dir_()

Print library base path

#### Example

```bash
```

_Function has no arguments._

#### Return with global $__ or $_\<MODULE\>__

* Library dir path

### package_load()

Load required package, cloning the git repository hosting it

#### Example

```bash
```

#### Arguments

* **$1** (string): Git repository url without scheme (https:// is used)

#### Exit codes

* Standard

#### Output on stdout

* Informative messages

#### Output on stderr

* Error messages


