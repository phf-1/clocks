if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

# Ip Port → Address
address() {
  ip_check "$1"
  local ip="$1"
  port_check "$2"
  local port="$2"
  echo "$ip:$port"
}

# Value → Boolean
is_address() {
  local address="$1"
  local ip port
  ip="${address%:*}"
  port="${address##*:}"
  is_ip "$ip" && is_port "$port"
}

# Any → Maybe(Error)
address_check() {
  local value="$1"
  if ! is_address "$value"; then
    failed_check "value is not a Address" "value=$value"
  fi
}

# Address → Ip
address_to_ip() {
  address_check "$1"
  local address="$1"
  echo "${address%:*}"
}

# Address → Port
address_to_port() {
  address_check "$1"
  local address="$1"
  echo "${address##*:}"
}
