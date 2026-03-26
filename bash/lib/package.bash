# Specification

# [[id:93da0b14-ce43-4c4d-a409-20608c073715]]
#
# TODO(b568)

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_PACKAGE ]] && return
_LIB_PACKAGE=1

source "${BASH_SOURCE[0]%/*}/fs.bash"
source "${BASH_SOURCE[0]%/*}/check.bash"

_PACKAGE="$(fs_root)/package"
dir_check "$_PACKAGE"

# Path → Package | Error ∧ (exit 1)
package_build() {
  local path="$1"
  if file_in_dir_pred "$path" "${_PACKAGE}"; then
    path="${path##*/}"
    echo "${path%.*}"
  else
    failed_check "path is not an package specification" "path=$path"
  fi
}

# Any → Boolean
is_package() {
  local name="$1"
  file_in_dir_pred "$_PACKAGE/$name.scm" "${_PACKAGE}"
}

# Any → Maybe(Error ∧ (exit 1))
package_check() {
  local value="$1"
  if ! is_package "$value"; then failed_check "value is not an Package" "value=$value"; fi
}

# Package → Path
package_spec() {
  package_check "$1"
  local package="$1"
  echo "$_PACKAGE/$package.scm"
}

# List(Package)
package_list() {
  for file in "$_PACKAGE"/*; do package_build "$file"; done
}

# Package → StorePath
package_build() {
  package_check "$1"
  local package="$1"
  guix build -L "$_PACKAGE" "$package"
}

# Package → String
package_string() {
  package_check "$1"
  local package="$1"
  local host_name
  host_name="$(package_host_name "$package")"
  local port
  port="$(package_ssh_port "$package")"
  echo "#Package(host-name=$host_name ssh-port=$port)"
}
