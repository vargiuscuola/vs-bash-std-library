#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$(dirname "${BASH_SOURCE[0]}")/../package.sh"
package.load "github.com/vargiuscuola/std-lib.bash"
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"
module.import "../main"
#module.import "../args"
#module.import "../info"
#module.import "../lock"

#{$.*[\^|]
	declare -a ary_literal=(	".*"	"[x]\\"	"[WW]"	"[^x]"	"]|S"	"$"	"^..."	"\\|E")
	declare -a ary_sep=(		""		"/"		"W"		"x"		"^"		"]"	"|"		".")


time (
for i in {1..100}; do
for idx in "${!ary_literal[@]}"; do
	literal="${ary_literal[$idx]}" sep="${ary_sep[$idx]}"
	escaped1="$( regexp_escape-ext-regexp-pattern "${literal}" "${sep}" )"
done
done
)

time (
for i in {1..100}; do
for idx in "${!ary_literal[@]}"; do
	literal="${ary_literal[$idx]}" sep="${ary_sep[$idx]}"
	regexp_escape-ext-regexp-pattern_ "${literal}" "${sep}"
	escaped2="$__"
done
done
)

exit
var="l1

l3"
time (
for i in {1..1000}; do
string_append -m "var" '.*' '#'
done
)

exit

var='* # % ? ? % ['



#time (
#for i in {1..1000}; do
#string_escape-bash-re-pattern2_ "$var"
#done
#)
#exit

var=
string.concat var x
echo var1="$var"
string.concat var y
echo var2="$var"
string.concat var z ,
echo var3="$var"

var="l1

l3"
echo var4=".${var}."
string_append2 -m var '.*' '#'
echo var4="$var"
exit

declare -a ary=(ab "c d" ef "g h i" l "c d")
array_find-indexes_ ary "c d"
declare -p __a

