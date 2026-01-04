# -*- mode: sh; eval: (sh-set-shell "zsh") -*-

############################################################################
# Standard Setup Behavior
############################################################################

# See https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# See https://wiki.zshell.dev/community/zsh_plugin_standard#standard-plugins-hash
declare -gA BREW
BREW[_PLUGIN_DIR]="${0:h}"
BREW[_ALIASES]=""
BREW[_FUNCTIONS]=""

#
# Public variables:
#
# `BREW_EXAMPLE`; if set it does something magical.
#

############################################################################
# Internal Support Functions
############################################################################

#
# This function will add to the `BREW[_FUNCTIONS]` list which is
# used at unload time to `unfunction` plugin-defined functions.
#
_brew_remember_fn() {
    emulate -L zsh

    local fn_name="${1}"
    if [[ -z "${BREW[_FUNCTIONS]}" ]]; then
        BREW[_FUNCTIONS]="${fn_name}"
    elif [[ ",${BREW[_FUNCTIONS]}," != *",${fn_name},"* ]]; then
        BREW[_FUNCTIONS]="${BREW[_FUNCTIONS]},${fn_name}"
    fi
}
_brew_remember_fn _brew_remember_fn

_brew_define_alias() {
    local alias_name="brew"
    local alias_value=""

    alias =

    if [[ -z  ]]; then
        BREW[_ALIASES]=""
    elif [[ ",," != *",,"* ]]; then
        BREW[_ALIASES]=","
    fi
}
_brew_remember_fn _brew_remember_alias

#
# This function does the initializtion of variables in the global variable
# `BREW`. It also adds to `path` and `fpath` as necessary.
# This variable is an associative array with the following private keys:
#
# - `_PLUGIN_DIR`; the directory the plugin is sourced from.
# - `_PLUGIN_BIN_DIR`; the directory (if present) for plugin specific binaries.
# - `_PLUGIN_FNS_DIR`; the directory (if present) for plugin autoload functions.
# - `_FUNCTIONS`; a list of all functions defined by the plugin.
#
_brew_plugin_init() {
    emulate -L zsh

    if command -v "${HOMEBREW_CMD}" >/dev/null 2>&1; then
        BREW[_CMD]="$(which brew)"
        BREW[_PREFIX]=$(${BREW[_CMD]} --prefix)

        eval "$(${BREW[_CMD]} shellenv)"
    else
        log_error "homebrew does not seem to be installed, setting defaults"
        export BREW[_PREFIX]="/opt/homebrew"
        BREW[_CMD]="${HOMEBREW_PREFIX}/bin/brew"
    fi

    # See https://wiki.zshell.dev/community/zsh_plugin_standard#functions-directory
    if [[ -d "${BREW[_PLUGIN_DIR]}/functions" ]]; then
        BREW[_PLUGIN_FNS_DIR]="${BREW[_PLUGIN_DIR]}/functions"

        if [[ $PMSPEC != *f* ]]; then
            # For compliant plugin managers
            fpath+=( "${BREW[_PLUGIN_FNS_DIR]}" )
        elif [[ ${zsh_loaded_plugins[-1]} != */brew && -z ${fpath[(r)${BREW[_PLUGIN_FNS_DIR]}]} ]]; then
            # For non-compliant plugin managers
            fpath+=( "${BREW[_PLUGIN_FNS_DIR]}" )
        fi

        local fn
        for fn in /*(.:t); do
            autoload -Uz ${fn}
            _brew_remember_fn ${fn}
        done
    fi
}
_brew_remember_fn _brew_plugin_init

############################################################################
# Plugin Unload Function
############################################################################

# See https://wiki.zshell.dev/community/zsh_plugin_standard#unload-function
brew_plugin_unload() {
    emulate -L zsh

    # Remove all remembered functions.
    local plugin_fns
    IFS=',' read -r -A plugin_fns <<< "${BREW[_FUNCTIONS]}"
    local fn
    for fn in ${plugin_fns[@]}; do
        whence -w "${fn}" &> /dev/null && unfunction "${fn}"
    done
    
    # Remove all remembered aliases.
    local aliases
    IFS=',' read -r -A aliases <<< "${BREW[_ALIASES]}"

    local alias
    # shellcheck disable=SC2068
    for alias in ${aliases[@]}; do
        unalias "${alias}"
    done

    # Remove the global data variable.
    unset BREW

    # Remove self from fpath.
    # shellcheck disable=SC2296
    fpath=("${(@)fpath:#${0:A:h}}")

    # Remove this function.
    unfunction "brew_plugin_unload"
}

############################################################################
# Initialize Plugin
############################################################################

_brew_plugin_init
true
