# datatypes.sh

Data types functions.

# Overview

Contains functions to manipulate different data types such as strings, arrays, associative arrays (hashes), lists, sets, regexps and datetime.
  It contains the following classes:
    * string
    * array
    * hash
    * list
    * set
    * regexp
    * datetime
  
  Use the command `module.doc <function_name>` to see the documentation for a function (see an [example](https://github.com/vargiuscuola/std-lib.bash#examples))


# Functions
* [string_append()](#string_append)
* [array_find-indexes_()](#array_find-indexes_)
* [array_find_()](#array_find_)
* [array_find()](#array_find)
* [array_include()](#array_include)
* [array_intersection_()](#array_intersection_)
* [array_remove-at()](#array_remove-at)
* [array_remove()](#array_remove)
* [array_remove-values()](#array_remove-values)
* [array_defined()](#array_defined)
* [array_init()](#array_init)
* [array_uniq_()](#array_uniq_)
* [array_eq()](#array_eq)
* [array_to_s()](#array_to_s)
* [list_find_()](#list_find_)
* [list_include()](#list_include)
* [hash_defined()](#hash_defined)
* [hash_init()](#hash_init)
* [hash_has-key()](#hash_has-key)
* [hash_merge()](#hash_merge)
* [hash_copy()](#hash_copy)
* [hash_find-value_()](#hash_find-value_)
* [hash_eq()](#hash_eq)
* [set_eq()](#set_eq)
* [regexp_escape-bash-pattern_()](#regexp_escape-bash-pattern_)
* [regexp_escape-ext-regexp-pattern_()](#regexp_escape-ext-regexp-pattern_)
* [regexp_escape-regexp-replace_()](#regexp_escape-regexp-replace_)
* [datetime_interval-to-sec_()](#datetime_interval-to-sec_)


## string_append()

Append a string to the content of the provided variable, optionally prefixing it with a separator if the variable is not empty.

### Aliases

* **string.append**

### Aliases

* **string.concat**

### Arguments

* **$1** (String): Variable name
* **$2** (String): String to append
* **$3** (String)[default: **" "**]: Separator

### Options

* **-m|--multi-line**: Append the string to every line of the destination variable

### Return with global scalar $__, array $__a or hash $__h

* Concatenation of the two strings, optionally separated by the provided separator

## array_find-indexes_()

Return the list of array's indexes which have the provided value.

### Aliases

* **array.find-indexes_**

### Arguments

* **$1** (String): Array name
* **$2** (String): Value to find

### Return with global scalar $__, array $__a or hash $__h

* An array of indexes of the array containing the provided value.

### Exit codes

* 0 if at least one item in array is found, 1 otherwise

### Example

```bash
$ declare -a ary=(a b c "s 1" d e "s 1")
$ array.find-indexes_ ary "s 1"
# return __a=(3 6)
```

## array_find_()

Return the index of the array containing the provided value, or -1 if not found.

### Aliases

* **array.find_**

### Arguments

* **$1** (String): Array name
* **$2** (String): Value to find

### Return with global scalar $__, array $__a or hash $__h

* The index of the array containing the provided value, or -1 if not found.

### Exit codes

* 0 if found, 1 if not found

### Example

```bash
$ declare -a ary=(a b c "s 1" d e "s 1")
$ array.find_ ary "s 1"
# return __=3
```

## array_find()

Print the index of the array containing the provided value, or -1 if not found.  
  It have the same syntax as `array.find_` but print the index found on stdout instead of the global variable `$__`

### Aliases

* **array.find_()**

#### See also

* [array_find_()](#array_find_())

## array_include()

Check whether an item is present in the provided array.

### Aliases

* **array.include**

### Arguments

* **$1** (String): Array name
* **$2** (String): Value to find

### Exit codes

* 0 if found, 1 if not found

### Example

```bash
$ declare -a ary=(a b c "s 1" d e "s 1")
$ array.include ary "s 1"
# exitcode=0
```

## array_intersection_()

Return an array containing the intersection between two arrays.

### Aliases

* **array.intersection_**

### Arguments

* **$1** (String): First array name
* **$2** (String): Second array name

### Return with global scalar $__, array $__a or hash $__h

* An array containing the intersection of the two provided arrays.

### Exit codes

* 0 if the intersection contains at least one element, 1 otherwise

### Example

```bash
$ declare -a ary1=(a b c d e f)
$ declare -a ary2=(b d g h)
$ array.intersection_ ary1 ary2
# return __a=(b d)
```

## array_remove-at()

Remove the item at the provided index from array.

### Aliases

* **array.remove-at**

### Arguments

* **$1** (String): Array name
* **$2** (String): Index of the item to remove

### Example

```bash
$ declare -a ary=(a b c d e f)
$ array.remove-at ary 2
$ declare -p ary
declare -a ary=([0]="a" [1]="b" [2]="d" [3]="e" [4]="f")
```

## array_remove()

Remove the first instance of the provided item from array.

### Aliases

* **array.remove**

### Arguments

* **$1** (String): Array name
* **$2** (String): Item to remove

### Exit codes

* 0 if item is found and removed, 1 otherwise

### Example

```bash
$ declare -a ary=(a b c d e a)
$ array.remove ary a
$ declare -p ary
declare -a ary=([0]="b" [1]="c" [2]="d" [3]="e" [4]="a")
```

## array_remove-values()

Remove any occurrence of the provided item from array.

### Aliases

* **array.remove-values**

### Arguments

* **$1** (String): Array name
* **$2** (String): Item to remove

### Example

```bash
$ declare -a ary=(a b c d e a)
$ array.remove-values ary a
$ declare -p ary
declare -a ary=([0]="b" [1]="c" [2]="d" [3]="e")
```

## array_defined()

Check whether an array with the provided name exists.

### Aliases

* **array.defined**

### Arguments

* **$1** (String): Array name

### Exit codes

* Standard (0 for true, 1 for false)

## array_init()

Initialize an array (resetting it if already existing).

### Aliases

* **array.init**

### Arguments

* **$1** (String): Array name

## array_uniq_()

Return an array with duplicates removed from the provided array.

### Aliases

* **array.uniq_**

### Arguments

* **$1** (String): Array name

### Return with global scalar $__, array $__a or hash $__h

* Array with duplicates removed

### Example

```bash
$ declare -a ary=(1 2 1 5 6 1 7 2)
$ array.uniq_ "${ary[@]}"
$ declare -p __a
declare -a __a=([0]="1" [1]="2" [2]="5" [3]="6" [4]="7")
```

## array_eq()

Compare two arrays

### Aliases

* **array.eq**

### Arguments

* **$1** (String): First array name
* **$2** (String): Second array name

### Exit codes

* 0 if the array are equal, 1 otherwise

### Example

```bash
$ declare -a ary1=(1 2 3)
$ declare -a ary2=(1 2 3)
$ array.eq ary1 ary2
# exitcode=0
```

## array_to_s()

Print a string with the definition of the provided array or hash (as shown in `declare -p` but without the first part declaring the variable).

### Aliases

* **array.to_s**

### Aliases

* **hash.to_s**

### Arguments

* **$1** (String): Array name

### Example

```bash
$ declare -a ary=(1 2 3)
$ array.to_s ary
([0]="1" [1]="2" [2]="3")
```

## list_find_()

Return the index inside a list in which appear the provided searched item.

### Aliases

* **list.find_**

### Aliases

* **list_include**
* **list.include**

### Arguments

* **$1** (String): Item to find
* **...** (String): Elements of the list

### Return with global scalar $__, array $__a or hash $__h

* The index inside the list in which appear the provided item.

### Exit codes

* 0 if the item is found, 1 otherwise

## list_include()

Check whether an item is included in a list of values.

### Aliases

* **list.include**

### Arguments

* **$1** (String): Item to find
* **...** (String): Elements of the list

### Exit codes

* 0 if the item is found, 1 otherwise

## hash_defined()

Check whether an hash with the provided name exists.

### Aliases

* **hash.defined**

### Arguments

* **$1** (String): Hash name

### Exit codes

* Standard (0 for true, 1 for false)

## hash_init()

Initialize an hash (resetting it if already existing).

### Aliases

* **hash.init**

### Arguments

* **$1** (String): Hash name

## hash_has-key()

Check whether a hash contains the provided key.

### Aliases

* **hash.has-key**

### Arguments

* **$1** (String): Hash name
* **$2** (String): Key name to find

### Exit codes

* Standard (0 for true, 1 for false)

## hash_merge()

Merge two hashes.

### Aliases

* **hash.merge**

### Arguments

* **$1** (String): Variable name of the 1st hash, in which to merge the 2nd hash
* **$2** (String): Variable name of the 2nd hash, which is merged into the 1st hash

### Example

```bash
$ declare -A h1=([a]=1 [b]=2 [e]=3)
$ declare -A h2=([a]=5 [c]=6)
$ hash.merge h1 h2
$ declare -p h1
declare -A h1=([a]="5" [b]="2" [c]="6" [e]="3" )
```

## hash_copy()

Copy an hash.

### Aliases

* **hash.copy**

### Arguments

* **$1** (String): Variable name of the hash to copy from
* **$2** (String): Variable name of the hash to copy to: if the hash is not yet defined, it will be created as a global hash

### Example

```bash
$ declare -A h1=([a]=1 [b]=2 [e]=3)
$ hash.copy h1 h2
$ declare -p h2
declare -A h2=([a]="1" [b]="2" [e]="3")
```

## hash_find-value_()

Return the key of the hash which have the provided value.

### Aliases

* **hash.find-value_**

### Arguments

* **$1** (String): Hash name
* **$2** (String): Value to find

### Example

```bash
$ declare -A h1=([a]=1 [b]=2 [e]=3)
$ hash.find-value_ h1 2
$ echo $__
b
```

## hash_eq()

Compare two hashes

### Aliases

* **hash.eq**

### Arguments

* **$1** (String): First hash name
* **$2** (String): Second hash name

### Exit codes

* 0 if the hashes are equal, 1 otherwise

### Example

```bash
$ declare -a h1=([key1]=val1 [key2]=val2)
$ declare -a h2=([key1]=val1 [key2]=val2)
$ hash.eq h1 h2
# exitcode=0
```

## set_eq()

Compare two sets (a set is an array where index associated to values are negligibles)

### Aliases

* **set.eq**

### Arguments

* **$1** (String): First array name
* **$2** (String): Second array name

### Exit codes

* 0 if the values of arrays are the same, 1 otherwise

### Example

```bash
$ declare -a ary1=(1 2 3 1 1)
$ declare -a ary2=(3 2 1 2 2)
$ set.eq ary1 ary2
# exitcode=0
```

## regexp_escape-bash-pattern_()

Escape a string which have to be used as a search pattern in a bash parameter expansion as ${parameter/pattern/string}.
 The escaped characters are `%*[?/`

### Aliases

* **regexp.escape-bash-pattern_**

### Arguments

* **$1** (String): String to be escaped

### Return with global scalar $__, array $__a or hash $__h

* Escaped string

### Example

```bash
$ regexp.escape-bash-pattern_ 'a * x #'
# return __=a \* x \#
```

## regexp_escape-ext-regexp-pattern_()

Escape a string which have to be used as a search pattern in a extended regexp in `sed` or `grep`.
  The escaped characters are the following: `{$.*[\^|]`.

### Aliases

* **regexp.escape-ext-regexp-pattern_**

### Arguments

* **$1** (String): String to be escaped
* **$2** (String)[default: **/**]: Separator used in the `sed` expression

### Return with global scalar $__, array $__a or hash $__h

* Escaped string

### Example

```bash
$ regexp.escape-ext-regexp-pattern_ "[WW]"  "W"
# return __=\[\W\W[]]
```

## regexp_escape-regexp-replace_()

Escape a string which have to be used as a replace string on a `sed` command.
  The escaped characters are the separator character and the following characters: `/&`.

### Aliases

* **regexp.escape-ext-regexp-pattern_**

### Arguments

* **$1** (String): String to be escaped
* **$2** (String)[default: **/**]: Separator used in the `sed` expression

### Return with global scalar $__, array $__a or hash $__h

* Escaped string

### Example

```bash
$ regexp.escape-regexp-replace_ "p/x"
# return __="p\/x"
$ regexp.escape-regexp-replace_ "x//" "x"
# return __="\x//"
```

## datetime_interval-to-sec_()

Convert the provided time interval to a seconds interval. The format of the time interval is the following:  
  [\<n\>d] [\<n\>h] [\<n\>m] [\<n\>s]

### Aliases

* **datetime.interval-to-sec_**

### Arguments

* **...** (String): Any of the following time intervals: \<n\>d (\<n\> days), \<n\>h (\<n\> hours), \<n\>m (\<n\> minutes) and \<n\>s (\<n\> seconds)

### Example

```bash
$ datetime.interval-to-sec_ 1d 2h 3m 45s
# return __=93825
```


