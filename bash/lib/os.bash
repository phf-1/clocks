# Specification

# [[id:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]]
#
# os : OS represents an [[ref:be4a5e39-7ec4-43ed-9d96-376db49ce782][OS]]
#
# To build an OS, add a definition to the appropriate directory
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))
# init : OS
# spec : OS → Path
# list : List(OS)
# ssh_port : OS → Port
# user : OS → User
# package_d : OS → Directory
# scheme : OS → Scheme
# machine : OS → [[ref:6ab03cba-6319-43bf-acc2-d74e77e95198][Machine]]
# name : OS → String

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_OS ]] && return
_LIB_OS=1

source "${BASH_SOURCE[0]%/*}/scheme.bash"
source "${BASH_SOURCE[0]%/*}/check.bash"

_OS_VM="$(scheme_root)/app/vm"
dir_check "$_OS_VM"

# [[id:317882b2-8907-4bda-89ed-a1d60793ddc3]]
_os_value() {
  local os="$1"
  local name="$2"
  # name ↦ (define %name value) ↦ value
  local value
  if ! value=$(rg -m 1 -o -I -r '$1' '\(define %'"$name"' +([^)]+)\)' "$(os_spec "$os")"); then
    failed_check "Cannot read var from os" "var=$name" "os=$os"
  fi
  # If the value is a string, e.g. "v", then return v
  [[ ${value:0:1} == '"' && ${value: -1:1} == '"' ]] && value="${value:1:-1}"
  echo "$value"
}

# Interface

os() {
  os_check "$1"
  echo "$1"
}

is_os() {
  local name="$1"
  file_in_dir_pred "$_OS_VM/$name/os.scm" "${_OS_VM}"
}

init_os() {
  local name="init"
  os_check "$name"
  echo "$name"
}

os_check() {
  local value="$1"
  if ! is_os "$value"; then failed_check "value is not an OS" "value=$value"; fi
}

os_spec() {
  os_check "$1"
  local os="$1"
  echo "$_OS_VM/$os/os.scm"
}

os_list() {
  for file in "$_OS_VM"/*; do echo "${file##*/}"; done
}

os_ssh_port() {
  os_check "$1"
  local os="$1"
  _os_value "$os" "ssh-port"
}

os_user() {
  os_check "$1"
  local os="$1"
  _os_value "$os" "user"
}

os_root_key() {
  os_check "$1"
  local os="$1"
  _os_value "$os" "root-pub-key"
}

os_store_key() {
  os_check "$1"
  local os="$1"
  _os_value "$os" "store-pub-key"
}

os_package_d() {
  os_check "$1"
  local os="$1"
  echo "$(dirname $(dirname "$spec"))"
}

os_scheme() {
  os_check "$1"
  local os="$1"
  echo "(begin (use-modules (os $os)) os)"
}

os_machine() {
  os_check "$1"
  local os="$1"
  echo "$os"
}

os_name() {
  os_check "$1"
  local os="$1"
  echo "$os"
}
