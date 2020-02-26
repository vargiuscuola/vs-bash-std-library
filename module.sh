#!/usr/bin/env bash
#github-action genshdoc

# @file module.sh
# @brief include shell libraries modules
# @show-internal
shopt -s expand_aliases
source "$(dirname "${BASH_SOURCE[0]}")/package.sh"

# @internal
# @description Return normalized absolute path
# @example
#   module.abs_path_ "../lib"
#   => /var/lib
# @arg $1 string Path
# @return Normalized absolute path
:module_abs_path_() {
    local path="$1"
    if [ -d "$path" ]; then
        pushd "$path" &>/dev/null
        declare -g _MODULE__="$PWD"
        popd &>/dev/null
    else
        pushd "${path%/*}" &>/dev/null
        declare -g _MODULE__="$PWD/${path##*/}"
        popd &>/dev/null
    fi
}
alias :module.abs_path_=":module_abs_path_"

# @environment _MODULE__IMPORTED_MODULES Imported modules
:module.abs_path_ "${BASH_SOURCE[0]}" && _MODULE__IMPORTED_MODULES=("$_MODULE__")
:module.abs_path_ "${BASH_SOURCE[-1]}" && _MODULE__IMPORTED_MODULES+=("$_MODULE__")

# @description Import module
# @example
#   module.import "githum/vargiuscuola/std-lib.bash/main"
# @arg $1 string Module path. Shell extension `.sh` can be omitted
# @exitcodes Standard
module_import() {
    local module="$1"
    :module.abs_path_ "$(dirname "${BASH_SOURCE[0]}")" && local path="$_MODULE__"
    :module.abs_path_ "$(dirname "${BASH_SOURCE[1]}")" && local caller_path="$_MODULE__"
    local module_path
    
    [[ "$module" =~ \.sh$ ]] || module="${module}.sh"
    
    # try absolute
    if [[ $module == /* ]] && [[ -e "$module" ]]; then
        module_path="$module"
    # try relative to caller
    elif [[ -f "${caller_path}/${module}" ]]; then
        module_path="${caller_path}/${module}"
    # try current package path
    elif [[ -f "${path}/${module}.sh" ]]; then
        module_path="${path}/${module}.sh"
    # try system wide lib dir
    else
        package.get-lib-dir_
        [[ -f "$_PACKAGE__/${module}" ]] && module_path="$_PACKAGE__/${module}"
    fi
    [[ -z "$module_path" ]] && { echo "[ERROR] failed to import \"$module\"" ; return 1 ; }
    # normalize module_path
    :module.abs_path_  "$module_path" && module_path="$_MODULE__"
    
    # check if module already loaded
    local loaded_module
    for loaded_module in "${_MODULE__IMPORTED_MODULES[@]}"; do
        [[ "$loaded_module" == "$module_path" ]] && return 0
    done
    
    _MODULE__IMPORTED_MODULES+=("$module_path")
    source "$module_path" || return 1
}
alias module.import="module_import"
