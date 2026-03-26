if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

frontend_root() { echo "$ROOT/frontend"; }
frontend_dist() { echo "$(frontend_root)/dist"; }
