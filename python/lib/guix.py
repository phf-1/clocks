# [[id:184e8f75-3a8f-40d1-9c1c-fe30dd50e083][Guix]]
#
# This module represents Guix CLI.

from __future__ import annotations
import subprocess
import os
from fs import Fs
from check import Check
from log import Log
from vm import Vm
from osys import Osys
from ip import Ip
from port import Port
from chars import String
from pathlib import Path
import tempfile

_MACHINE_TEMPLATE = """__OS__

(use-modules
 ((gnu machine))
 ((gnu machine ssh)))

(define %host-name "__IP__")
(define %ssh-port __PORT__)
(define %host-key "__HOST_KEY__")

(list
 (machine
  (environment managed-host-environment-type)
  (configuration
   (machine-ssh-configuration
    (host-name %host-name)
    (port %ssh-port)
    (host-key (string-join `("ssh-ed25519" ,%host-key) " "))
    (system "x86_64-linux")))
  (operating-system os)))
"""

def _machine_path(os, ip, port, host_key):
    os_str = Osys.use_modules(os)
    ip_str = Ip.string(ip)
    port_str = str(Port.int(port))
    String.check(host_key)
    template = _MACHINE_TEMPLATE.replace("__IP__", ip_str)
    template = template.replace("__PORT__", port_str)
    template = template.replace("__HOST_KEY__", host_key)
    template = template.replace("__OS__", os_str)
    tmp_d = Path(tempfile.mkdtemp(prefix="app_"))
    machine = tmp_d / "machine.scm"
    with open(machine, mode="w", encoding="utf-8") as f:
        f.write(template)
    return machine

class Guix:
    """
    Module :≡ List(String)
    Params :≡ List(String)
    deploy : Module Params → subprocess.CompletedProcess
    repl : ∅
    container_is_active : Boolean
    container_check : Maybe(Error)
    """

    @staticmethod
    def deploy(vm, os):
        Vm.check(vm)
        Osys.check(os)
        ip = Vm.ip(vm)
        port = Vm.ssh_port(vm)
        if not Vm.is_running(vm, 2):
            Log.info("Start the Dev VM outside the container with ,vm-init-start port", f"port: {port}")
            Check.failed("Dev VM is not running.", f"ip: {ip}", f"port: {port}")

        host_key = Vm.host_key(vm)
        machine = _machine_path(os, ip, port, host_key)
        subprocess.run(
            ["guix", "time-machine", "-C", str(Fs.channels()), "--", "deploy", str(machine)],
            check=True
        )

    @staticmethod
    def build(path):
        cmd = ["guix", "time-machine", "-C", str(Fs.channels()), "--", "build", "-q", "-f", f"{path}"]
        subprocess.run(cmd, check=True)
        return Guix

    @staticmethod
    def repl():
        init = Fs.scheme() / ".guile"
        cmd = ["guix", "repl", "-i", init]
        subprocess.run(cmd)

    @staticmethod
    def container_is_active():
        return "GUIX_ENVIRONMENT" in os.environ

    @staticmethod
    def container_check():
        if not Guix.container_is_active():
            Check.error("Guix container is not active")
