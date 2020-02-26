#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../package.sh"
package.load "github.com/vargiuscuola/rebash" --update
source "$(package.get-lib-dir)/github.com/vargiuscuola/rebash/core.sh"

package.load "github.com/vargiuscuola/std-lib.bash" --update
core.import "github.com/vargiuscuola/std-lib.bash/main.sh" false
