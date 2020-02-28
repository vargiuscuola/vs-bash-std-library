# module.sh

Include shell libraries modules

## Environments Variables

* **\_MODULE__IMPORTED_MODULES** (Array): Imported modules


## Functions
* [module_import()](#module_import)


### module_import()

Import module

#### Example

```bash
```

#### Arguments

* **$1** (String): Module path. Shell extension `.sh` can be omitted

#### Exit codes

* Standard



## Internal Functions
* [:module_abs-path_()](#module_abs-path_)


### :module_abs-path_()

Return normalized absolute path

#### Example

```bash
```

#### Arguments

* **$1** (String): Path

#### Return with global $__ or $_\<MODULE\>__

* Normalized absolute path


