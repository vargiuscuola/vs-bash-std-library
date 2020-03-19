# docs.sh

Include shell libraries modules

# Global Variables

* **\_INFO__SHDOC_DIR** (String): Path of the package github.com/vargiuscuola/shdoc (used by the function `info_show` and his alias `info.show`


# Functions
* [info_list-class-functions()](#info_list-class-functions)
* [info_show()](#info_show)


## info_list-class-functions()

List the functions of the provided class, which must be already loaded with `module.import` or at least `source`-ed.

### Aliases

* **info.list-class-functions**

### Arguments

* **$1** (String): Class name

### Output on stdout

* List of functions which are part of the provided class

### Example

```bash
$ info.list-class-functions args
args.check-number
args.parse
args_check-number
args_parse
args_to_str_
```

## info_show()

Show the documentation of the provided function.

### Aliases

* **info.show**

### Arguments

* **$1** (String): Function name

### Output on stdout

* Show the documentation of the provided function

### Example

```bash
$ info.show args.check-number
```


