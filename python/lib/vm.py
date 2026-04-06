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

from __future__ import annotations
import subprocess
import time
from pathlib import Path

from check import Check
from image import Image
from osys import Osys
from port import Port
from ip import Ip
import shutil

_VM_TMP = Path("/tmp/clocks/vm")
_VM_TMP.mkdir(parents=True, exist_ok=True)

def _system_check() -> None:
    for cmd in ("socat", "qemu-system-x86_64", "qemu-img", "wget", "systemd-run", "systemctl"):
        if shutil.which(cmd) is None:     
            Check.failed("required command not found", f"cmd={cmd}")

    if not Path("/dev/kvm").exists():
        Check.failed("KVM is not available")

def _host_key(ip, port):
    result = subprocess.run(
        ["ssh-keyscan", "-T", "1", "-t", "ed25519", "-p", str(port), str(ip)],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0 and "ssh-ed25519" in result.stdout:
        return result.stdout.strip().split()[-1]
    return None

def _name(image):
    return Image.name(image)

def _unit(image):
    return f"vm-{_name(image)}"

def _socket(image) -> Path:
    return _VM_TMP / f"{_name(image)}.sock"

def _clean(image) -> None:
    unit = _unit(image)
    subprocess.run(["systemctl", "--user", "reset-failed", unit])
    _socket(image).unlink(missing_ok=True)

def _start(image, ip, ssh_port):
    if not _is_running(ip, ssh_port, 2):
        _system_check()
        _clean(image)
        unit = _unit(image)
        qcow2 = Image.qcow2(image)
        socket = _socket(image)
        cmd = [
            "systemd-run", "--user",
            "--unit", unit,
            "qemu-system-x86_64",
            "-enable-kvm",
            "-cpu", "host",
            "-m", "8192",
            "-drive", f"file={qcow2},format=qcow2,if=virtio",
            "-snapshot",
            "-device", "virtio-net-pci,netdev=net0",
            "-netdev", f"user,id=net0,hostfwd=tcp::{ssh_port}-:22",
            "-chardev", f"socket,id=mon,path={socket},server=on,wait=off",
            "-mon", "chardev=mon,mode=control",
        ]
        subprocess.run(cmd)
        _is_running_check(ip, ssh_port, timeout=20)            
    
def _is_running(ip, port, timeout) -> bool:
    start = time.time()
    while time.time() - start < timeout:
        time.sleep(0.5)
        if _host_key(ip, port) is not None:
            return True
    return False

def _is_running_check(ip, port, timeout) -> None:
    if not _is_running(ip, port, timeout):
        Check.failed("VM is not running", f"ip={ip}", f"port={port}", f"timeout={timeout} sec")

def _root_key(image):
    osys = Image.osys(image)
    return Osys.root_key(osys)

def _store_key(image):
    osys = Image.osys(image)
    return Osys.store_key(osys)

# Interface

class Vm:
    def __init__(self, image, ssh_port):
        Image.check(image)  
        Port.check(ssh_port)
        self._image = image
        self._ssh_port = ssh_port
        # TODO(5e4b): generalize to arbitrary IP 
        self._ip = Ip("127.0.0.1")

    @staticmethod
    def is_a(vm) -> bool:
        return isinstance(vm, Vm)

    @staticmethod
    def check(vm) -> None:
        if not Vm.is_a(vm):
            Check.failed("value is not a representation of a VM", f"value={vm}")

    @staticmethod
    def elim(func):
        def closure(vm):
            Vm.check(vm)
            return func(vm._image, vm._ip, vm._ssh_port)
        return closure

    @staticmethod
    def name(vm):
        return Vm.elim(lambda image, ip, port: _name(image))(vm)

    @staticmethod
    def ip(vm):
        return Vm.elim(lambda image, ip, port: ip)(vm)

    @staticmethod
    def ssh_port(vm):
        return Vm.elim(lambda image, ip, port: port)(vm)

    @staticmethod
    def host_key(vm):
        Vm.check(vm)
        if hasattr(vm, '_host_key'):
            return vm._host_key
        else:
            vm._host_key = Vm.elim(lambda image, ip, port: _host_key(ip,port))(vm)
            return vm._host_key

    @staticmethod
    def start(vm):
         Vm.elim(lambda image, ip, port: _start(image,ip,port))(vm)
         return vm
        
    @staticmethod
    def root_key(vm):
        Vm.check(vm)
        if hasattr(vm, '_root_key'):
            return vm._root_key
        else:
            vm._root_key = Vm.elim(lambda image, ip, port: _root_key(image))(vm)
            return vm._root_key

    @staticmethod
    def store_key(vm):
        Vm.check(vm)
        if hasattr(vm, '_store_key'):
            return vm._store_key
        else:
            vm._store_key = Vm.elim(lambda image, ip, port: _store_key(image))(vm)
            return vm._store_key

    @staticmethod
    def is_running(vm, timeout):
        return Vm.elim(lambda image, ip, port: _is_running(ip, port, timeout))(vm)

    @staticmethod
    def is_running_check(vm, timeout):
        return Vm.elim(lambda image, ip, port: _is_running_check(ip, port, timeout))(vm)

    @staticmethod
    def clean(vm):
        Vm.elim(lambda image, ip, port: _clean(image))(vm)
