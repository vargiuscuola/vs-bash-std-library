#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$(dirname "${BASH_SOURCE[0]}")/../package.sh"
package.load "github.com/vargiuscuola/std-lib.bash"
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"

module.import "../main"
module.import "../lock"

( get_lock 10 10 prova ; sleep 100 ) &
lock.kill prova
echo RET=$?
exit

#( get_lock prova ; sleep 100 ) &
echo "PID=$( cat "$_LOCK__RUN_DIR"/prova.pid )"
pid=$(<"$_LOCK__RUN_DIR"/prova.pid)
echo "PID2=$pid"
wait $pid
echo END

#module.import "github.com/vargiuscuola/std-lib.bash/main.sh"
