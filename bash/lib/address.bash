# Specification

# [[id:b8b14535-4b8f-43e0-9a0d-fd11f167db7e][Authority]]
#
# An Authority represents an [[ref:56eb52ec-d0e8-4f03-8199-9ca69887c0c5][Authority]]
#
# authority : Ip Port → Authority
# is? : Any → Boolean
# check : Any → Any → Maybe(Error ∧ (exit 1))
# ip : Authority → Ip
# port : Authority → Port

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_AUTHORITY ]] && return
_LIB_AUTHORITY=1

source "${BASH_SOURCE[0]%/*}/check.bash"
source "${BASH_SOURCE[0]%/*}/ip.bash"
source "${BASH_SOURCE[0]%/*}/port.bash"

# Interface

authority() {
  ip_check "$1"
  local ip="$1"
  port_check "$2"
  local port="$2"
  echo "authority|$(ip_string "$ip")|$(port_string "$port")"
}

is_authority() {
  IFS='|' read -r tag _ _ <<< "$1"
  [[ "$tag" == "authority" ]]
}

authority_check() {
  local value="$1"
  if ! is_authority "$value"; then
    failed_check "value is not a Authority" "value=$value"
  fi
}

authority_ip() {
  authority_check "$1"
  IFS='|' read -r _ str _ <<< "$1"
  echo "$(ip "$str")"
}

authority_port() {
  authority_check "$1"
  IFS='|' read -r _ _ str <<< "$1"
  echo "$(port "$str")"
}
