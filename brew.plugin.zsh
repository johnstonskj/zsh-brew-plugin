# -*- mode: sh; eval: (sh-set-shell "zsh") -*-
#
# @name brew
# @brief Simple environment setup for using `brew` as a package manager.
# @repository https://github.com/johnstonskj/zsh-brew-plugin
#

############################################################################
# @section Lifecycle
# @description Plugin lifecycle functions.
#

brew_plugin_init() {
    emulate -L zsh

    @zplugins_envvar_save brew HOMEBREW_CMD
    @zplugins_envvar_save brew HOMEBREW_PREFIX

    if command -v brew > /dev/null 2>&1; then
        export HOMEBREW_CMD="$(which brew)"

        eval "$(${HOMEBREW_CMD} shellenv)"
    else
        log_error "homebrew does not seem to be installed, setting defaults"
        export HOMEBREW_PREFIX="/opt/homebrew"
        export HOMEBREW_CMD="${HOMEBREW_PREFIX}/bin/brew"
    fi
}

# @internal
brew_plugin_unload() {
    emulate -L zsh

    @zplugins_envvar_restore brew HOMEBREW_CMD
    @zplugins_envvar_restore brew HOMEBREW_PREFIX
}
