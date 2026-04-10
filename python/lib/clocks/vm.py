from __future__ import annotations
import subprocess
from pathlib import Path

from clocks.check import Check
from clocks.image import Image
from clocks.osys import Osys
from clocks.port import Port
from clocks.nat import Nat
from clocks.ssh import Ssh
from clocks.authority import Authority
from clocks.ip import Ip
import os
import shutil

_VM_TMP = Path("/tmp/clocks/vm")
_VM_TMP.mkdir(parents=True, exist_ok=True)


def _system_check() -> None:
    for cmd in (
        "socat",
        "qemu-system-x86_64",
        "qemu-img",
        "wget",
        "systemd-run",
        "systemctl",
    ):
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


def _purge_systemd_user_unit(unit_name):
    """
    Safely stops, disables, and deletes a systemd user unit and its related files.
    Silences errors if the unit does not exist.
    """

    # 1. Stop and disable the unit (silently ignore if it doesn't exist/isn't running)
    subprocess.run(
        ["systemctl", "--user", "stop", unit_name],
        stderr=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
    )
    subprocess.run(
        ["systemctl", "--user", "disable", unit_name],
        stderr=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
    )

    # 2. Ask systemd for the exact path to the unit file
    show_cmd = subprocess.run(
        ["systemctl", "--user", "show", "-p", "FragmentPath", "--value", unit_name],
        capture_output=True,
        text=True,
    )
    unit_path = show_cmd.stdout.strip()

    # 3. Delete the file (and any drop-in directories) if it was found
    if unit_path and os.path.exists(unit_path):
        try:
            os.remove(unit_path)
            print(f"Removed unit file: {unit_path}")
        except OSError as e:
            print(f"Error removing file {unit_path}: {e}")

        # Check for and remove drop-in config folders (e.g., ~/.config/systemd/user/vm-dev.service.d/)
        drop_in_dir = f"{unit_path}.d"
        if os.path.exists(drop_in_dir):
            shutil.rmtree(drop_in_dir, ignore_errors=True)
            print(f"Removed drop-in directory: {drop_in_dir}")

    # 4. Reload the daemon so systemd realizes the file is gone
    subprocess.run(
        ["systemctl", "--user", "daemon-reload"],
        stderr=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
    )

    # 5. Reset the failed state (silencing the specific error you were previously seeing)
    subprocess.run(
        ["systemctl", "--user", "reset-failed", unit_name],
        stderr=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
    )


def _clean(image) -> None:
    unit = _unit(image)
    _purge_systemd_user_unit(unit)
    _socket(image).unlink(missing_ok=True)


def _start(image, ip, ssh_port):
    if not Ssh.is_running(Authority.mk(ip, ssh_port), Nat.mk(2)):
        _system_check()
        _clean(image)
        unit = _unit(image)
        qcow2 = Image.qcow2(image)
        socket = _socket(image)
        cmd = [
            "systemd-run",
            "--user",
            "--unit",
            unit,
            "qemu-system-x86_64",
            "-enable-kvm",
            "-cpu",
            "host",
            "-m",
            "8192",
            "-drive",
            f"file={qcow2},format=qcow2,if=virtio",
            "-snapshot",
            "-device",
            "virtio-net-pci,netdev=net0",
            "-netdev",
            f"user,id=net0,hostfwd=tcp::{ssh_port}-:22",
            # TODO(3df4): make the VM reply on the host port http_port=8080
            # "-netdev", f"user,id=net0,hostfwd=tcp::{ssh_port}-:22,hostfwd=tcp::{http_port}-:80",
            "-chardev",
            f"socket,id=mon,path={socket},server=on,wait=off",
            "-mon",
            "chardev=mon,mode=control",
        ]
        subprocess.run(cmd)
        Ssh.is_running_check(Authority.mk(ip, ssh_port), Nat.mk(20))


def _root_key(image):
    osys = Image.osys(image)
    return Osys.root_key(osys)


def _store_key(image):
    osys = Image.osys(image)
    return Osys.store_key(osys)


class Vm:
    """
    [[id:ef1de6fd-1c16-459f-9564-02bbe5917396][VM]]

    A VM represents a [[ref:6ea36050-ce4a-44fe-b263-3ddb4a9e066c][VirtualMachine]].
    """

    def __init__(self, image, ssh_port):
        Image.check(image)
        Port.check(ssh_port)
        self._image = image
        self._ssh_port = ssh_port
        # TODO(5e4b): generalize to arbitrary IP
        self._ip = Ip("127.0.0.1")

    @staticmethod
    def mk(image, ssh_port) -> Vm:
        Image.check(image)
        Port.check(ssh_port)
        return Vm(image, ssh_port)

    @staticmethod
    def dev(ssh_port, inside_container) -> Vm:
        Port.check(ssh_port)
        osys = Osys.dev()
        image = Image.mk(osys, inside_container=inside_container)
        return Vm.mk(image, ssh_port)

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
        if hasattr(vm, "_host_key"):
            return vm._host_key
        else:
            vm._host_key = Vm.elim(lambda image, ip, port: _host_key(ip, port))(vm)
            return vm._host_key

    @staticmethod
    def start(vm):
        Vm.elim(lambda image, ip, port: _start(image, ip, port))(vm)
        return vm

    @staticmethod
    def root_key(vm):
        Vm.check(vm)
        if hasattr(vm, "_root_key"):
            return vm._root_key
        else:
            vm._root_key = Vm.elim(lambda image, ip, port: _root_key(image))(vm)
            return vm._root_key

    @staticmethod
    def store_key(vm):
        Vm.check(vm)
        if hasattr(vm, "_store_key"):
            return vm._store_key
        else:
            vm._store_key = Vm.elim(lambda image, ip, port: _store_key(image))(vm)
            return vm._store_key

    @staticmethod
    def is_running(vm: Vm, timeout: Nat) -> bool:
        Nat.check(timeout)
        return Vm.elim(
            lambda image, ip, port: Ssh.is_running(Authority.mk(ip, port), timeout)
        )(vm)

    @staticmethod
    def is_running_check(vm: Vm, timeout: Nat):
        Nat.check(timeout)
        return Vm.elim(
            lambda image, ip, port: Ssh.is_running_check(
                Authority.mk(ip, port), timeout
            )
        )(vm)

    @staticmethod
    def clean(vm: Vm):
        Vm.elim(lambda image, ip, port: _clean(image))(vm)
