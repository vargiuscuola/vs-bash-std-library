#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$(dirname "${BASH_SOURCE[0]}")/../package.sh"
package.load "github.com/vargiuscuola/std-lib.bash"
source "$(dirname "${BASH_SOURCE[0]}")/../module.sh"

module.import "../main"
module.import "../trap"

trap.add-handler "echo ok" EXIT
idx1=$_TRAP__
trap.add-handler "echo ok2" EXIT
idx2=$_TRAP__
trap.disable-handler EXIT $idx1
trap.disable-handler EXIT $idx2
#module.import "github.com/vargiuscuola/std-lib.bash/main.sh"
