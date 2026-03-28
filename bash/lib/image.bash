# Specification

# [[id:0c323aa3-4e48-4d72-83cf-9481324cf274]] 
# image : [[ref:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]] → Image :≡
#   os ↦ represents the [[ref:2b855eac-c24c-4d19-a966-e8bf89be994c][DiskImage]] of os
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1)) 
# os : Image → OS
# qcow2 : Image → Path
# list : List(Image)

# Implementation

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# TODO(59a4): try to only go through sysd, not through files like pid file

# Define the set of Image images
_Image="$_ROOT/image"

# Interface

image() {
  os_check "$1"
  local os="$1"
  local spec
  spec="$(os_spec "$os")"
  local qcow2
  qcow2="$_Image/$os.qcow2"
  if [[ -f "$qcow2" ]] && [[ "$qcow2" -nt "$spec" ]]; then
    : Re-building the image is not necessary.
  else
    set -x 
    cp -f "$(guix system image -t qcow2 --image-size=20G "$spec")" "$qcow2"
  fi
  local image="$os"
  echo "$image"
}

is_image() {
  local name="$1"
  file_in_dir_pred "$_Image/$name.qcow2" "${_Image}";
}

image_check() {
  local value="$1"
  if ! is_image "$value"; then
    failed_check "value is not a representation of a Image" "value=$value";
  fi
}

image_os() {
  image_check "$1"
  local image="$1"
  echo "$1"
}

image_qcow2() {
  image_check "$1"
  local image="$1"
  echo "$_Image/$image.qcow2";
}

image_list() {
  for path in "$_Image"/*; do
    path="${path##*/}"
    echo "${path%.*}"
  done
}
