from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

from clocks.authority import Authority
from clocks.check import Check
from clocks.fs import Fs
from clocks.ip import Ip
from clocks.maybe import Maybe
from clocks.nat import Nat
from clocks.osys import Osys
from clocks.port import Port
from clocks.string import String
from clocks.cmd import Cmd
from dataclasses import dataclass, field
from clocks.machine import Machine
from types import ModuleType
import shutil


def _add_load_paths(cmd, load_paths):
    next_cmd = cmd.copy()
    if load_paths:
        for load_path in load_paths:
            next_cmd.append("-L")
            next_cmd.append(str(load_path))
    return next_cmd


@dataclass
class Guix:
    """
    [[id:184e8f75-3a8f-40d1-9c1c-fe30dd50e083][Guix]]

    guix : Guix represents an instance of the [[ref:4a69ece7-49dc-40b1-9ff3-419aadedf385][GuixCli]].
    """

    _Ssh: ModuleType = field(init=False, repr=False)

    def __post_init__(self):
        from clocks.ssh import Ssh

        self._Ssh = Ssh

    def mk() -> Guix:
        """Guix"""
        return Guix()

    @staticmethod
    def is_a(value) -> bool:
        """Any → Boolean

        Return true iff value is an instance of Guix
        """

        return isinstance(value, Guix)

    @staticmethod
    def check(value):
        """Any → ∅

        Raise an exception iff value is not an instance of Guix
        """
        if not Guix.is_a(value):
            Check.failed("value is not a Guix", f"value={value}")

    @staticmethod
    def deploy(guix: Guix, os: Osys, authority: Authority):
        """os:Osys auth:Authority → os is deployed on the machine represented by auth"""

        Guix.check(guix)
        Osys.check(os)
        Authority.check(authority)
        Ssh = guix._Ssh
        Ssh.is_running_check(authority, Nat.mk(2))
        key = Maybe.value(Ssh.host_key(authority))
        machine = Machine.mk(os, authority, key)
        try:
            tmp_d = Path(tempfile.mkdtemp(suffix="-guix"))
            file = Machine.install(machine, tmp_d)
            cmd = [
                "guix",
                "time-machine",
                "-C",
                str(Fs.channels()),
                "--",
                "deploy",
                "-L",
                str(tmp_d),
                str(file),
            ]
            breakpoint()
            subprocess.run(cmd, check=True)
        finally:
            if tmp_d is not None:
                shutil.rmtree(tmp_d)

    @staticmethod
    def build(guix: Guix, path: Path, load_paths=[]):
        """Path List(Path) → StorePath"""

        cmd = [
            "guix",
            "time-machine",
            "-C",
            str(Fs.channels()),
            "--",
            "build",
        ]

        cmd = _add_load_paths(cmd, load_paths)

        cmd += ["-f", str(path)]

        return Path(Cmd.run(cmd))

    @staticmethod
    def repl(guix: Guix):
        """Start a Guix REPL"""
        init = Fs.scheme() / ".guile"
        cmd = ["guix", "repl", "-i", init]
        subprocess.run(cmd, check=False)

    @staticmethod
    def container_is_active(guix: Guix):
        return "GUIX_ENVIRONMENT" in os.environ

    @staticmethod
    def container_check(guix: Guix):
        if not Guix.container_is_active(guix):
            Check.failed("Guix container is not active")
