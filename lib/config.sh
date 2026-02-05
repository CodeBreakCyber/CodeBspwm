# Common configuration variables for installer
# shellcheck shell=bash

# ShellCheck: SC2034 - Variables intended for export/source
# shellcheck disable=SC2034
: "${XDG_CONFIG_HOME:=$HOME/.config}"
# shellcheck disable=SC2034
PROJECT_NAME="KaliBspwm"
# shellcheck disable=SC2034
PROJECT_VERSION="2.1"
# shellcheck disable=SC2034
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
DEFAULT_THEME_DIR="${XDG_CONFIG_HOME}/polybar/scripts/themes"
