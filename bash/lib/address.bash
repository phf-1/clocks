if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# address :≡ ip ":" port

# Implementation

is_address() {
  local address="$1"
  local ip port
  ip="${address%:*}"
  port="${address##*:}"
  is_ip "$ip" && is_port "$port"
}
address_check() {
  local address="$1"
  if ! is_address "$address"; then
    failed_check "address is not a Address" "address=$address"
  fi
}
