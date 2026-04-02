# Specification

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Implementation

source "${BASH_SOURCE[0]%/*}/fs.bash"
source "${BASH_SOURCE[0]%/*}/check.bash"

_EMACS_D="$(fs_root)/emacs.d"
dir_check "$_EMACS_D"

# Interface
