# Specification

# [[id:ef1de6fd-1c16-459f-9564-02bbe5917396][VM]]
#
# A VM represents a [[ref:6ea36050-ce4a-44fe-b263-3ddb4a9e066c][VirtualMachine]].
#
# vm : [[ref:0c323aa3-4e48-4d72-83cf-9481324cf274][Image]] → Vm
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))
# image : Vm → Image
# running? : Vm Timeout → Boolean
# running_check : Vm Timeout → Maybe(Error ∧ (exit 1))
# vm_system_check : Maybe(Error ∧ (exit 1))
# status : Vm → String
# stop : Vm → Vm
# clean : Vm → Vm (underlying filesystem has been cleaned)
# name : Vm → String

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_VM ]] && return
_LIB_VM=1

_Vm_TMP="/tmp/clocks/vm"
mkdir -p "$_Vm_TMP"

_vm_socket() {
  vm_check "$1"
  local vm="$1"
  echo "$_Vm_TMP/$vm.sock"
}

_vm_unit() {
  vm_check "$1"
  local vm="$1"
  echo "vm-$vm"
}

# Socket … → Send … to the socket
_vm_socket_send() {
  local sock="$1"
  shift
  printf '%s\n' "$@" | socat - "UNIX-CONNECT:${sock}"
}

# socket:Socket → a QMP quit message has been sent to socket
_vm_qmp_quit() {
  local sock="$1"
  _vm_socket_send "$sock" '{"execute":"qmp_capabilities"}{"execute":"quit"}'
}

# socket:Socket → a QMP status message has been sent to socket
_vm_qmp_status() {
  local sock="$1"
  _vm_socket_send "$sock" '{"execute":"qmp_capabilities"}{"execute":"query-status"}'
}

_vm_os() {
  local vm="$1"
  local image
  image="$(vm_image "$vm")"
  echo "$(image_os "$image")"
}

_vm_machine() {
  local vm="$1"
  local os
  os="$(_vm_os "$vm")"
  echo "$(os_machine "$os")"
}

_vm_ip() {
  local vm="$1"
  local machine="$(_vm_machine "$1")"
  echo "$(machine_ip "$machine")"
}

_vm_port() {
  local vm="$1"
  local machine="$(_vm_machine "$1")"
  echo "$(machine_ssh_port "$machine")"
}

_vm_qcow2() {
  local vm="$1"
  local image="$(vm_image "$1")"
  echo "$(image_qcow2 "$image")"
}

# Interface

vm_system_check() {
  if [[ -v GUIX_ENVIRONMENT ]]; then failed_check "This command should not execute in the container"; fi
  for cmd in socat qemu-system-x86_64 qemu-img wget systemd-run systemctl; do cmd_check "$cmd"; done
  if [[ ! -w /dev/kvm ]]; then failed_check "KVm is not available"; fi
}

vm() {
  image_check "$1"
  local image="$1"
  local host_port="$(_vm_port "$vm")"
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
      -netdev user,id=net0,hostfwd=tcp::"${host_port}"-:22 \
      -device virtio-net-pci,netdev=net0 \
      -chardev socket,id=mon,path="$(_vm_socket "$vm")",server=on,wait=off \
      -mon chardev=mon,mode=control \
      2>/dev/null
    vm_is_running_check "$vm" "15"
  fi
  echo "$vm"
}

is_vm() {
  local name="$1"
  is_image "$1"
}

vm_check() {
  local value="$1"
  if ! is_vm "$value"; then
    failed_check "value is not a representation of a Vm" "value=$value"
  fi
}

vm_image() {
  vm_check "$1"
  local vm="$1"
  echo "$vm"
}

vm_is_running() {
  vm_check "$1"
  local vm="$1"

  nat_check "$2"
  local timeout="$2"

  local ip
  ip="$(_vm_ip "$vm")"

  local port
  port="$(_vm_port "$vm")"

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

vm_is_running_check() {
  vm_check "$1"
  local vm="$1"

  nat_check "$2"
  local timeout="$2"

  if ! msg="$(vm_is_running "$vm" "$timeout")"; then
    failed_check "Vm is not responsive" \
      "vm=$vm" "ip=$(_vm_ip "$vm")" "port=$(_vm_port "$vm")" "$msg"
  fi
}

vm_status() {
  vm_check "$1"
  local vm="$1"
  vm_is_running_check "$vm" "2"
  _vm_qmp_status "$(_vm_socket "$vm")"
}

vm_stop() {
  vm_check "$1"
  local vm="$1"
  if vm_is_running "$vm" "2"; then
    _vm_qmp_quit "$(_vm_socket "$vm")"
    local unit
    unit="$(_vm_unit "$vm")"
    while systemctl --user is-active --quiet "$unit" 2>/dev/null; do sleep 1; done
  fi
  vm_clean "$vm"
}

vm_clean() {
  vm_check "$1"
  local vm="$1"
  local unit
  unit="$(_vm_unit "$vm")"
  systemctl --user stop "$unit" 2>/dev/null || true
  systemctl --user reset-failed "$unit" 2>/dev/null || true
  rm -f "$(_vm_socket "$vm")"
}

vm_name() {
  vm_check "$1"
  local vm="$1"
  echo "$vm"
}
