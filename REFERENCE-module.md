# module.sh

include shell libraries modules

## Environments Variables

* **_MODULE__IMPORTED_MODULES**: Imported modules


## Functions
* [:module_abs_path_()](#module_abs_path_)
* [module_import()](#module_import)


### :module_abs_path_()

Return normalized absolute path

#### Example

```bash
module.abs_path_ "../lib"
=> /var/lib
```

#### Arguments

* **$1** (string): Path

#### Return with global $__ or $_\<MODULE\>__

* Normalized absolute path

### module_import()

Import module

#### Example

```bash
module.import "githum/vargiuscuola/std-lib.bash/main"
=> /var/lib
```

#### Arguments

* **$1** (string): Module path. Shell extension `.sh` can be omitted

#### Exit codes

* **0**: On success
* **1**: On failure


