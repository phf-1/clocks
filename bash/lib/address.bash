# Specification

# [[id:b8b14535-4b8f-43e0-9a0d-fd11f167db7e]]
#
# addr: Address represents an address, e.g. 127.0.0.1:8080.
#
# address : Ip Port → Address
# is? : Any → Boolean
# check : Any → Any → Maybe(Error ∧ (exit 1))
# ip : Address → Ip
# port : Address → Port

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

source "${BASH_SOURCE[0]%/*}/check.bash"

# Interface

address() {
  ip_check "$1"
  local ip="$1"
  port_check "$2"
  local port="$2"
  echo "$ip:$port"
}

is_address() {
  local value="$1"
  local ip="${value%:*}"
  local port="${value##*:}"
  is_ip "$ip" && is_port "$port"
}

address_check() {
  local value="$1"
  if ! is_address "$value"; then
    failed_check "value is not a Address" "value=$value"
  fi
}

address_ip() {
  address_check "$1"
  local address="$1"
  echo "${address%:*}"
}

address_to_port() {
  address_check "$1"
  local address="$1"
  echo "${address##*:}"
}
