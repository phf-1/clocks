from __future__ import annotations
import subprocess
import os
from clocks.fs import Fs
from clocks.check import Check
from clocks.maybe import Maybe
from clocks.osys import Osys
from clocks.ip import Ip
from clocks.nat import Nat
from clocks.port import Port
from clocks.string import String
from clocks.authority import Authority
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

def _machine(os: Osys, authority: Authority, host_key: str) -> Path:
    ip = Authority.ip(authority)
    port = Authority.port(authority)
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
    [[id:184e8f75-3a8f-40d1-9c1c-fe30dd50e083][Guix]]

    This module represents Guix CLI.

    Module :≡ List(String)
    Params :≡ List(String)
    """

    @staticmethod
    def deploy(os: Osys, authority: Authority):
        """os:Osys auth:Authority → os is deployed on auth"""
        Osys.check(os)
        Authority.check(authority)
        # Python import system is kind of dumb
        from clocks.ssh import Ssh
        Ssh.is_running_check(authority, Nat.mk(2))
        host_key = Maybe.value(Ssh.host_key(authority))
        machine = _machine(os, authority, host_key)
        subprocess.run(
            ["guix", "time-machine", "-C", str(Fs.channels()), "--", "deploy", str(machine)],
            check=True
        )

    @staticmethod
    def build(path):
        """TODO(626d): this should return the Path of the artefact"""
        cmd = ["guix", "time-machine", "-C", str(Fs.channels()), "--", "build", "-q", "-f", f"{path}"]
        subprocess.run(cmd, check=True)
        return Guix

    @staticmethod
    def repl():
        """Start a Guix REPL"""
        init = Fs.scheme() / ".guile"
        cmd = ["guix", "repl", "-i", init]
        subprocess.run(cmd)

    @staticmethod
    def container_is_active():
        return "GUIX_ENVIRONMENT" in os.environ

    @staticmethod
    def container_check():
        if not Guix.container_is_active():
            Check.failed("Guix container is not active")
