# Specification

# [[id:6ab03cba-6319-43bf-acc2-d74e77e95198][Machine]]
#
# A Machine represents a machine on the network, i.e. it has an Ip and listens on ports.
#
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))
# spec : Machine → Path
# ip : Machine → Ip
# ssh_port : Machine → Port
# host_key : Machine → [[ref:97eca5fe-b140-44c7-81d9-51f2a3f4454f][Ed25519Pub]]
# name : Machine → String
# list : List(Machine)
# live? : Machine → Boolean
# live_check : Machine → Maybe(Error ∧ (exit 1))
# parse : String → Machine (parse ▸ serialize = identity)
# serialize : Machine → String (serialize ▸ parse = identity)

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_MACHINE ]] && return
_LIB_MACHINE=1

source "${BASH_SOURCE[0]%/*}/scheme.bash"
source "${BASH_SOURCE[0]%/*}/check.bash"

_MACHINE="$(scheme_root)/app/vm"
dir_check "$_MACHINE"

# [[id:aa625827-d060-4211-a1a9-8d97db13b3c5]]
#
# Machine Name → Value | Error ∧ (exit 1)
_machine_var() {
  machine_check "$1"
  local machine="$1"
  local name="$2"
  # name ↦ (define %name value) ↦ value
  local value
  if ! value=$(rg -m 1 -o -I -r '$1' '\(define %'"$name"' +([^)]+)\)' "$(machine_spec "$machine")"); then
    failed_check "Cannot read var from machine" "var=$name" "machine=$machine"
  fi
  # If the value is a string, e.g. "v", then return v
  [[ ${value:0:1} == '"' && ${value: -1:1} == '"' ]] && value="${value:1:-1}"
  echo "$value"
}

# Interface

is_machine() {
  local name="$1"
  file_in_dir_pred "$_MACHINE/$machine/machine.scm" "${_MACHINE}"
}

machine_check() {
  local value="$1"
  if ! is_machine "$value"; then failed_check "value is not an Machine" "value=$value"; fi
}

machine_spec() {
  machine_check "$1"
  local machine="$1"
  echo "$_MACHINE/$machine/machine.scm"
}

machine_list() {
  for file in "$_MACHINE"/*; do echo "${file##*/}"; done
}

machine_ip() {
  machine_check "$1"
  local machine="$1"
  _machine_var "$machine" "host-name"
}

machine_ssh_port() {
  machine_check "$1"
  local machine="$1"
  _machine_var "$machine" "ssh-port"
}

machine_host_key() {
  machine_check "$1"
  local machine="$1"
  local ip
  ip="$(machine_ip "$machine")"
  local port
  port="$(machine_ssh_port "$machine")"
  if result="$(ssh-keyscan -t ed25519 -p "$port" "$ip")"; then
    awk '/ssh-ed25519/ { print $2 " " $3 }' <<<"$result"
  else
    return 1
  fi
}

machine_is_live() {
  machine_check "$1"
  local machine="$1"
  local ip
  ip="$(machine_ip "$machine")"
  local port
  port="$(machine_ssh_port "$machine")"
  nat_check "$2"
  local timeout="$2"
  local start_time=$SECONDS
  local key
  while ((SECONDS - start_time < timeout)); do
    key="$(ssh-keyscan -T 1 -t ed25519 -p "$port" "$ip" 2>/dev/null)"
    if rg -F 'ed25519' <<<"$key" &>/dev/null; then
      return 0
    fi
  done
  return 1
}

machine_is_live_check() {
  machine_check "$1"
  local machine="$1"
  not_implemented
  ip_check "$2"
  local ip="$2"
  port_check "$3"
  local port="$3"
  nat_check "$4"
  local timeout="$4"
  if ! msg="$(machine_is_live "$machine" "$ip" "$port" "$timeout")"; then
    failed_check "Machine is not responsive" \
      "machine=$machine" "ip=$ip" "port=$port" "$msg"
  fi
}

machine_serialize() {
  machine_check "$1"
  local machine="$1"
  local host_name
  ip="$(machine_ip "$machine")"
  local port
  port="$(machine_ssh_port "$machine")"
  echo "#Machine(host-name=$host_name ssh-port=$port)"
}

machine_parse() {
  machine_check "$1"
  local machine="$1"
  not_implemented
}

machine_parse() {
  machine_check "$1"
  local machine="$1"
  echo "$machine"
}
