# Specification

# [[id:b394674a-148b-4f10-9c5e-1166e8b86793]]
#
# This module represents the filesystem.
#
# fs_root : Directory

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_FS ]] && return
_LIB_FS=1

_ROOT="$(git rev-parse --show-toplevel)"

# Interface

fs_root() {
  echo "$_ROOT"
}
