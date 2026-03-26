if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

# The set of OS specifications
_OS="$ROOT/os"

# Given a name, return the associated OS specification
os_spec() {
  local name="$1"
  local file="$_OS/$name.scm"
  echo "$file"
}

# to build an OS, add an os specification to $_OS

# List the OS
os_list() {
  for file in "$_OS"/*; do
    file="${file##*/}"
    echo "${file%.*}"
  done
}

# An OS is the name of an OS specification
is_os() {
  local name="$1"  
  file_in_dir_pred "$(os_spec "$name")" "${_OS}";
}

# Given a name and it is not an OS, then exit with an error
os_check() {
  local name="$1"
  if ! is_os "$name"; then failed_check "name is not an OS" "os=$name"; fi
}

# Given a variable name and an OS, return the associated value for the OS
os_var() {
  local name="$1"
  local os="$2"
  os_check "$os"
  # name ↦ (define %name value) ↦ value
  local value
  if ! value=$(rg -o -I -r '$1' '\(define %'"$name"' +([^)]+)\)' "$(os_spec "$os")"); then
    failed_check "Cannot read var from os" "var=$name" "os=$os"
  fi
  echo "$value"
}

# Given an OS, return its ssh port 
os_ssh_port() {
  local os="$1"
  os_check "$os"
  os_var "ssh-port" "$os"
}
