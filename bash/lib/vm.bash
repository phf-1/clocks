###############
# Specification
#
#   TODO(fa1d)

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

################
# Implementation

# Define the set of VM images
_VM="$ROOT/vm"

# TODO(b43b): fix that, should be unique
_VM_TMP="$TMPDIR/clocks/vm"
mkdir -p "$_VM_TMP"

# Given an OS, return a VM
vm_build() {
  local os="$1"
  os_check "$os"
  local path
  path="$(vm_path "$os")"
  cp -f "$(guix system image -t qcow2 "$(os_spec "$os")")" "$path"
  chmod u+w "$path"
  echo "$os"
}

# A VM is the name of a VM QCOW2 image in $_VM
is_vm() {
  file_in_dir_pred "$(vm_path "$1")" "${_VM}"
}

# Given a name, return the path of its QCOW2 image, if any
vm_path() { echo "$_VM/$1.qcow2"; }

# List VMs
vm_list() {
  for file in "$_VM"/*; do
    file="${file##*/}"
    echo "${file%.*}"
  done
}

# Given a name and it is not a VM, then exit with an error
vm_check() {
  local name="$1"
  if ! is_vm "$name"; then failed_check "vm is not a VM" "vm=$name"; fi
}

# Given a VM, return the associated socket, if any
vm_sock_file() {
  local vm="$1"
  vm_check "$vm"
  echo "$_VM_TMP/$vm.sock";
}

# Given a VM, return the associated pid file, if any
vm_pid_file() {
  local vm="$1"
  vm_check "$vm"
  echo "$_VM_TMP/$vm.pid";
}

# Given a VM, decide if the associated VM is running
vm_is_running() {
  local vm="$1"
  vm_check "$vm"
  local pid_file
  pid_file="$(vm_pid_file "$vm")"
  # TODO(6da5): explain
  [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null
}

# If the current system should not or cannot run a VM, then exit with an error
vm_check_os() {
  if [[ -v GUIX_ENVIRONMENT ]]; then failed_check "This command should not execute in the container"; fi
  for cmd in socat qemu-system-x86_64 qemu-img wget systemd-run systemctl; do cmd_check "$cmd"; done
  if [[ ! -w /dev/kvm ]]; then failed_check "KVM is not available"; fi
}


# Given VM, return its unit name
vm_unit() {
  local vm="$1"
  vm_check "$vm"
  echo "vm-$vm";
}

# Given a VM and a port, then start it so that it is reachable by SSH through the port
vm_start() {
  local vm="$1"
  vm_check "$vm"
  local host_port="$2"
  port_check "$host_port"
  local os_port
  os_port="$(os_ssh_port "$vm")" # os ~ vm  
  if ! vm_is_running "$vm"; then
    vm_check_os
    local pid_file
    pid_file="$(vm_pid_file "$vm")"
    local vm_sock
    vm_sock="$(vm_sock_file "$vm")"
    # Clean up any stale unit from a previous run
    local unit
    unit="$(vm_unit "$vm")"    
    systemctl --user stop "$unit" 2>/dev/null || true
    systemctl --user reset-failed "$unit" 2>/dev/null || true
    rm -f "$pid_file" "$vm_sock"    
    systemd-run --user \
                --unit="$unit" \
                qemu-system-x86_64 \
                -enable-kvm \
                -cpu host \
                -m 4096 \
                -drive file="$(vm_path "$vm")",format=qcow2,if=virtio \
                -netdev user,id=net0,hostfwd=tcp::"${host_port}"-:"${os_port}" \
                -device virtio-net-pci,netdev=net0 \
                -chardev socket,id=mon,path="${vm_sock}",server=on,wait=off \
                -mon chardev=mon,mode=control
    systemctl --user show -p MainPID --value "$unit" > "$pid_file"
    # TODO(c014): replace with a poll on ssh port 
    waiting_sec=5
    echo "Wait for the VM to start" "waiting_sec=$waiting_sec sec"
    sleep "$waiting_sec"
  fi
}

# Given a socket, send it a message
_vm_qmp() {
  local sock="$1"; shift
  printf '%s\n' "$@" | socat - "UNIX-CONNECT:${sock}"
}

# Given a VM, ask it to shutdown
vm_qmp_quit() {
  local vm="$1"
  vm_check "$vm"
  local sock
  sock="$(vm_sock_file "$vm")"
  printf '{"execute":"qmp_capabilities"}\n{"execute":"quit"}\n' \
    | socat - "UNIX-CONNECT:${sock},ignoreeof"
}

# Given a VM, ask it its status
vm_qmp_status() {
  local vm="$1"
  vm_check "$vm"    
  _vm_qmp "$(vm_sock_file "$vm")" '{"execute":"qmp_capabilities"}{"execute":"query-status"}'
}

# Given a VM, return its status
vm_status() {
  local vm="$1"
  vm_check "$vm"
  if ! vm_is_running "$vm"; then
    info "VM is stopped" "vm=${vm}"
  else
    local status
    status="$(vm_qmp_status "$vm")"
    local pid
    pid="$(cat "$(vm_pid_file "$vm")")"
    echo "VM is running os=${vm} pid=${pid} status=${status}"
  fi
}

# Given a VM, stop its execution
vm_stop() {
  local vm="$1"
  vm_check "$vm"
  if vm_is_running "$vm"; then
    vm_qmp_quit "$vm"
    local unit
    unit="$(vm_unit "$vm")"
    while systemctl --user is-active --quiet "$unit" 2>/dev/null; do sleep 1; done
    local sock
    sock="$(vm_sock_file "$vm")"
    local pid_file
    pid_file="$(vm_pid_file "$vm")"    
    rm -f "$sock" "$pid_file"
    systemctl --user reset-failed "$unit" 2>/dev/null || true
  fi
}
