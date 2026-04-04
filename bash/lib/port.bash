# Specification

# [[id:bbabbbd6-cd92-44b3-91b7-095c979f7f45][Port]]
#
# port : Port represents a port
# is? : Any → Boolean
# check : Any → Mayeb(Error ∧ (exit 1))

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_PORT ]] && return
_LIB_PORT=1

source "${BASH_SOURCE[0]%/*}/check.bash"

# Interface


port() {
  port_check "$1"
  echo "$1"
}


is_port() {
  local port="$1"
  if [[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)); then
    return 0
  else
    return 1
  fi
}

port_check() {
  local value="$1"
  if ! is_port "$value"; then
    failed_check "value is not a Port" "value=$value"
  fi
}

port_number() {
  port_check "$1"
  echo "$1"
}
