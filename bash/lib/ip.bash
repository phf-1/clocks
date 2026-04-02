# Specification

# ip : Ip represents an [[ref:2e06869b-d68d-4683-a3e6-84357b245e3d][Ip]]
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

source "${BASH_SOURCE[0]%/*}/check.bash"

# Interface

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
