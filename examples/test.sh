#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$(dirname "${BASH_SOURCE[0]}")/../package.sh"
package.load "github.com/vargiuscuola/std-lib.bash"
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"

module.import "../main"
module.import "../trap"

trap.add-handler TRAP1 "echo END1" EXIT
trap.add-handler TRAP2 "echo END2" EXIT
trap.add-handler TRAPx "echo Ctrl-c" INT
exit
trap.set-function-handler "echo RUN \${_TRAP__FUNCTION_NAME}"
fff() { echo "run func f()"; }
fff
fff
fff


exit
trap.set-function-handler

set -o functrace
trap_func() {
	echo "Run ${FUNCNAME[2]}"
}
trap.add-handler "echo Run \${FUNCNAME[1]}" RETURN
#module.import "github.com/vargiuscuola/std-lib.bash/main.sh"
