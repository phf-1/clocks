if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

is_port() {
  local port="$1"
  if [[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)); then
    return 0
  else
    return 1
  fi
}
port_check() {
  local port="$1"
  if ! is_port "$port"; then
    failed_check "port is not a Port" "port=$port"
  fi
}
