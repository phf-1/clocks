# Specification

# [[id:ef1de6fd-1c16-459f-9564-02bbe5917396][VM]]
#
# A VM represents a [[ref:6ea36050-ce4a-44fe-b263-3ddb4a9e066c][VirtualMachine]].
#
# vm : [[ref:0c323aa3-4e48-4d72-83cf-9481324cf274][Image]] [[ref:bbabbbd6-cd92-44b3-91b7-095c979f7f45][Port]] → VM
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))
# image : VM → Image
# running? : VM Timeout → Boolean
# running_check : VM Timeout → Maybe(Error ∧ (exit 1))
# vm_system_check : Maybe(Error ∧ (exit 1))
# status : VM → String
# stop : VM → VM
# clean : VM → VM (underlying filesystem has been cleaned)
# name : VM → String

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_VM ]] && return
_LIB_VM=1

source "${BASH_SOURCE[0]%/*}/check.bash"
source "${BASH_SOURCE[0]%/*}/image.bash"
source "${BASH_SOURCE[0]%/*}/port.bash"

_VM_TMP="/tmp/clocks/vm"
mkdir -p "$_VM_TMP"

# VM → Path
_vm_socket() {
  echo "$_VM_TMP/$(vm_name "$1").sock"
}

# VM → [[ref:fe5c4a72-2092-45e3-b2eb-31bc68db53bc][SysdUnitName]]
_vm_unit() {
  echo "vm-$(vm_name "$1")"
}

# VM → Path
_vm_qcow2() {
  local image="$(vm_image "$1")"
  echo "$(image_qcow2 "$image")"
}

# VM → [[ref:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]]
_vm_os() {
  image_os "$(vm_image $1)"
}

# Interface

vm_system_check() {
  if [[ -v GUIX_ENVIRONMENT ]]; then failed_check "This command should not execute in the container"; fi
  for cmd in socat qemu-system-x86_64 qemu-img wget systemd-run systemctl; do cmd_check "$cmd"; done
  if [[ ! -w /dev/kvm ]]; then failed_check "KVM is not available"; fi
}

vm() {
  image_check "$1"
  local image="$1"
  port_check="$2"
  local port="$2"
  local vm="vm|$(port_number "$port")|$(image_name "$image")"
  if ! vm_is_running "$vm" "2"; then
    vm_system_check
    vm_clean "$vm"
    local unit
    unit="$(_vm_unit "$vm")"
    systemd-run --user \
      --unit="$unit" \
      qemu-system-x86_64 \
      -enable-kvm \
      -cpu host \
      -m 8192 \
      -drive file="$(_vm_qcow2 "$vm")",format=qcow2,if=virtio \
      -snapshot \
      -device virtio-net-pci,netdev=net0 \
      -netdev user,id=net0,hostfwd=tcp::"${port}"-:22 \
      -chardev socket,id=mon,path="$(_vm_socket "$vm")",server=on,wait=off \
      -mon chardev=mon,mode=control \
      2>/dev/null
    vm_is_running_check "$vm" "15"
  fi
  echo "$vm"
}

is_vm() {
  IFS='|' read -r tag _ _ <<< "$1"
  [[ "$tag" == "vm" ]]
}

vm_check() {
  local value="$1"
  if ! is_vm "$value"; then
    failed_check "value is not a representation of a VM" "value=$value"
  fi
}

vm_image() {
  vm_check "$1"
  IFS='|' read -r _ _ name <<< "$1"
  echo "$(image "$name")"
}

vm_name() {
  vm_check "$1"
  IFS='|' read -r _ _ name <<< "$1"
  echo "$name"
}

vm_ssh_port() {
  vm_check "$1"
  IFS='|' read -r _ number _ <<< "$1"
  echo "$(port "$number")"
}

vm_ip() {
  vm_check "$1"
  local vm="$1"
  echo "127.0.0.1"
}

vm_is_running() {
  vm_check "$1"
  local vm="$1"
  nat_check "$2"
  local timeout="$2"
  local start_time=$SECONDS
  while ((SECONDS - start_time < timeout)); do
    sleep 0.5
    if vm_host_key "$vm" &>/dev/null; then
      return 0
    fi
  done
  return 1
}

vm_is_running_check() {
  vm_check "$1"
  local vm="$1"
  nat_check "$2"
  local timeout="$2"
  if ! vm_is_running "$vm" "$timeout" &>/dev/null; then
    failed_check "VM is not running" "vm=$vm" "ip=$(vm_ip "$vm")" "port=$(vm_ssh_port "$vm")"
  fi
}

vm_status() {
    vm_check "$1"
    systemctl --user status "$(_vm_unit "$1")"
}

vm_host_key() {
  vm_check "$1"
  local ip
  ip="$(vm_ip "$vm")"
  ip="$(ip_string "$ip")"
  local port
  port="$(vm_ssh_port "$vm")"
  port="$(port_number "$port")"
  if key="$(ssh-keyscan -T 1 -t ed25519 -p "$port" "$ip" 2>/dev/null)"; then
    echo "$key" | rg -F 'ed25519' | awk '{ print $2 " " $3 }'
  else
    return 1
  fi
}

vm_root_key() {
  vm_check "$1"
  os="$(_vm_os "$1")"
  os_root_key "$os"
}

vm_store_key() {
  vm_check "$1"
  os="$(_vm_os "$1")"
  os_store_key "$os"
}

vm_stop() {
    vm_check "$1"
    local unit
    unit="$(_vm_unit "$1")"
    systemctl --user stop "$unit" 2>/dev/null || true
    vm_clean "$1"
}

vm_clean() {
    vm_check "$1"
    local vm="$1"
    local unit
    unit="$(_vm_unit "$vm")"
    systemctl --user reset-failed "$unit" 2>/dev/null || true
    rm -f "$(_vm_socket "$vm")"
}
