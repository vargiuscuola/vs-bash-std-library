#!/bin/bash
#github-action genshdoc

# @file Library import.bash

[[ "$( uname -a  )" =~ ^MINGW ]] && _import__lib_dir=/c/linux-lib/sh || _import__lib_dir=/lib/sh

import_clone-git-module() {
    local git_module="$1"
    local lib_dir="$_std_lib__lib_dir/$git_module"
    local git_url="https://$git_module"
    local module_name="${git_module##*/}"
    
    [ -d "$lib_dir" ] && { echo "Module $git_module already present in $lib_dir" >&2 ; return 0 ; }
    echo -n "Cloning $git_url... "
    git clone --single-branch "$git_url" "$lib_dir" &>/dev/null && echo "[OK]" || { echo "[ERROR] Cannot clone $git_url" >&2 ; return 0 ; }
    return 0
}
alias import.clone-git-module="import_clone-git-module"

import_

import.clone-git-module "github.com/reconquest/import.bash"
