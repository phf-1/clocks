if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

is_ip() {
  local ip="$1"
  if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 0
  else
    return 1
  fi
}
ip_check() {
  local ip="$1"
  if ! is_ip "$ip"; then
    failed_check "ip is not a Ip" "ip=$ip"
  fi
}
