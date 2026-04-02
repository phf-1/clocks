# Specification

# [[id:3d172e70-2743-497d-a2b2-893cbd847c01]]
#
# TODO(f070)

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

source "${BASH_SOURCE[0]%/*}/fs.bash"
source "${BASH_SOURCE[0]%/*}/check.bash"

_BASH="$(fs_root)/bash"
dir_check "$_BASH"

_BASH_BIN="$_BASH/bin"
dir_check "$_BASH_BIN"

_BASH_ETC="$_BASH/etc"
dir_check "$_BASH_ETC"

# Interface

bash_analyze() {
  # TODO(7680)
  shellcheck -x "$_BASH"
}

bash_bash_profile() {
  echo "$_BASH_ETC/bash_profile"
}

bash_bash_bin() {
  echo "$_BASH_BIN"
}

bash_bashrc() {
  echo "$_BASH_ETC/bashrc"
}

bash_format() {
  shfmt -i 2 -w "$_BASH"
}
