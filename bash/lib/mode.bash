if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

mode_dev() { echo dev; }
mode_test() { echo test; }
mode_prod() { echo prod; }
mapfile -t _MODES < <(
  mode_dev
  mode_test
  mode_prod
)
mode_check() {
  local mode="$1"
  value_in_check "$mode" "${_MODES[@]}"
}
