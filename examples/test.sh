#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$(dirname "${BASH_SOURCE[0]}")/../package.sh"
package.load "github.com/vargiuscuola/std-lib.bash"
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"

#module.import "../reconquest-args/args"
module.import "../main"
module.import "../args"

declare -A opts
declare -a args

args.parse
args.parse - -av -b: -n:,--name -- -aav --name=pippo arg1 arg2
args.parse opts args -av -b: -n:,--name -- -aav --name=pippo arg1 arg2
declare -p opts
declare -p args

exit
module.import "../lock"
set -e

trap.enable-trace
trap.add-error-handler CHECKERR trap.show-stack-trace
#trap.add-handler EXIT1 "trap.show-stack-trace" EXIT
#trap.add-handler EXIT2 "echo EXIT" EXIT
#trap.add-handler INT "echo INT" INT
#f
lock.list_ ""
lock.new "" 5s 1m && echo OK || echo NO
lock.list_ "" ; declare -p __a
sleep 1000