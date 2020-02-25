# Library main.sh

Generic bash library functions (management of messages, traps, arrays, hashes, strings, etc.)

## Functions
* [get_ext_color()](#getextcolor)


### get_ext_color()

Get extended terminal color codes

#### Arguments

* **$1** (number): Foreground color
* **$2** (number): Background color

#### Example

```bash
get_ext_color 208
  => \e[38;5;208m
```

#### Exit codes

* n.a.

#### Output on stdout

* Color code.


