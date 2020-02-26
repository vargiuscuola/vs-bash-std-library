#!/usr/bin/env bash
#github-action genshdoc

# @file package.sh
# @brief load shell libraries packages as git repositories
shopt -s expand_aliases

# @param _PACKAGE__LIB_DIR string[/lib/sh in Linux - /c/linux-lib/sh in Windows] Shell Libraries Path
[[ "$( uname -a  )" =~ ^MINGW ]] && _PACKAGE__LIB_DIR=/c/linux-lib/sh || _PACKAGE__LIB_DIR=/lib/sh

# @description Print library base path
#
# @example
#   package.get-lib-dir
#   => /lib/sh
# @noargs
# @stdout Library path
package_get-lib-dir() {
    echo "$_PACKAGE__LIB_DIR"
}
alias package.get-lib-dir="package_get-lib-dir"

# @description Load required package, cloning the git repository hosting it
#
# @example
#   package.load github.com/vargiuscuola/std-lib.bash
# @arg $1 string Git repository url without scheme (https:// is used)
# @exitcode 0  If successfull
# @exitcode >0 On failure
# @stdout Informative messages
# @stderr Error messages
package_load() {
    local is_update git_package
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--update) is_update=true ; shift ;;
			*) [[ -n "$git_package" ]] && { echo "[ERROR] Argument error" >&2 ; return 1 ; } ; git_package="$1" ; shift ;;
		esac
	done
    local lib_dir="$_PACKAGE__LIB_DIR/$git_package"
    local git_url="https://$git_package"
    
    if [[ ! -d "$lib_dir" ]]; then
        echo "Cloning $git_url..."
        git clone --single-branch "$git_url" "$lib_dir" &>/dev/null && echo "[OK] $git_url cloned successfully" || { echo "[ERROR] Error cloning $git_url" >&2 ; return 1 ; }
    fi
    
    [[ ! -d "$lib_dir" ]] && { echo "Missing git repository in $lib_dir" >&2 ; return 1 ; }
    ( cd "$lib_dir" &>/dev/null && git fsck &>/dev/null ) || { echo "[ERROR] The git repository in $lib_dir is broken" >&2 ; return 1 ; }
    ( cd "$lib_dir" &>/dev/null && git fetch --prune &>/dev/null ) || { echo "[ERROR] Cannot check updates from origin" >&2 ; return 1 ; }
    if [[ "$is_update" == true ]]; then
        local local_commitid="$(cd "$lib_dir" && git rev-parse master)"
        local remote_commitid="$(cd "$lib_dir" && git rev-parse origin/master)"
        if [[ "$local_commitid" != "$remote_commitid" ]]; then
            echo "Updating git repository in $lib_dir..."
            ( cd "$lib_dir" &>/dev/null && git reset --hard "$remote_commitid" ) && echo "[OK] repository updated successfully" || { echo "[ERROR] The git repository cannot be updated" >&2 ; return 1 ; }
        fi
    fi
    
    return 0
}
alias package.load="package_load"
