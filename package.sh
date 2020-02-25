#!/usr/bin/env bash
#github-action genshdoc

# @file Library package.sh

[[ "$( uname -a  )" =~ ^MINGW ]] && _std_lib__lib_dir=/c/linux-lib/sh || _std_lib__lib_dir=/lib/sh

package_load-from-git() {
    local is_update git_package
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--update) is_update=true ; break ;;
			*) git_package="$1" ; break ;;
		esac
	done
    local lib_dir="$_std_lib__lib_dir/$git_package"
    local git_url="https://$git_package"
    
    if [[ ! -d "$lib_dir" ]]; then
        echo -n "Cloning $git_url... "
        git clone --single-branch "$git_url" "$lib_dir" &>/dev/null && echo "[OK]" || { echo "[ERROR] Error cloning $git_url" >&2 ; return 1 ; }
    fi
    
    [[ ! -d "$lib_dir" ]] && { echo "Missing git repository in $lib_dir" >&2 ; return 1 ; }
    ! { cd "$lib_dir" && git fsck &>/dev/null; } && { echo "[ERROR] The git repository in $lib_dir is broken" >&2 ; return 1 ; }
    if [[ is_update == true ]]; then
        local local_commitid="$(cd "$lib_dir" && git rev-parse master)"
        local remote_commitid="$(cd "$lib_dir" && git rev-parse origin/master)"
        if [[ "$local_commitid" != "$remote_commitid" ]]; then
            echo -n "Updating git repository in $lib_dir... "
#            git fetch --prune &>/dev/null
#            git reset --hard "$remote_commitid" && echo "[OK]" || { echo "[ERROR] The git repository cannot be updated" ; return 1 ; }
        fi
    fi
    
    return 0
}
alias package.load-from-git="package_load-from-git"