#!/usr/bin/env bash
#github-action genshdoc

# @file package.sh
# @brief Load shell libraries packages as git repositories
# @show-internal
shopt -s expand_aliases

# @setting _PACKAGE__LIB_DIR string[/lib/sh in Linux or /c/linux-lib/sh in Windows] shell libraries base path
if [[ -z "$_PACKAGE__LIB_DIR" ]]; then
	[[ "$( uname -a  )" =~ ^MINGW ]] && _PACKAGE__LIB_DIR=/c/linux-lib/sh || _PACKAGE__LIB_DIR=/lib/sh
fi

# @description Print library base path
# @alias package.get-lib-dir_
# @noargs
# @return Library dir path
# @example
#  $ package.get-lib-dir_
#      return> /lib/sh
package_get-lib-dir_() {
	declare -g __="$_PACKAGE__LIB_DIR"
}
alias package.get-lib-dir_="package_get-lib-dir_"

# @description Load required package, cloning the git repository hosting it
# @alias package.load
# @arg $1 String Git repository url without scheme (https is used)
# @exitcodes Standard
# @stdout Informative messages
# @stderr Error messages
# @example
#  $ package.load github.com/vargiuscuola/std-lib.bash
package_load() {
	local is_update is_check git_package
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--update) is_update=true ; shift ;;
			--check) is_check=true ; shift ;;
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
	if [[ "$is_check" == true ]]; then
		( cd "$lib_dir" &>/dev/null && git fsck &>/dev/null ) || { echo "[ERROR] The git repository in $lib_dir is broken" >&2 ; return 1 ; }
	fi
	if [[ "$is_update" == true ]]; then
		( cd "$lib_dir" &>/dev/null && git fetch --prune &>/dev/null ) || { echo "[ERROR] Cannot check updates from origin" >&2 ; return 1 ; }
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
