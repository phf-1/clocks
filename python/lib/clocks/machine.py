from __future__ import annotations
from dataclasses import dataclass
from clocks.check import Check
from clocks.string import String
from clocks.fs import Fs
from clocks.string import String
from clocks.authority import Authority
from clocks.osys import Osys
from clocks.module import Module
from clocks.ip import Ip
from clocks.port import Port


_MACHINE_TEMPLATE = (Fs.python_data() / "machine.scm").read_text()


@dataclass
class Machine:
    """
    [[id:cadffda5-86f5-413b-86f2-5e7d2235c131][Machine]]

    A machine is a representation of a [[ref:a99835ae-90fb-4021-8d1b-a49f741c1152][Machine]].
    """

    _os: Osys
    _auth: Authority
    _key: str

    @staticmethod
    def mk(os: Osys, auth: Authority, key: str) -> Machine:
        """Os Authority String → Machine

        Given an OS, an authority and a ed25519 host key represented by a string,
        then define a [[ref:cadffda5-86f5-413b-86f2-5e7d2235c131][Machine]].
        """

        Osys.check(os)
        Authority.check(auth)
        String.check(key)
        return Machine(os, auth, key)

    @staticmethod
    def elim(func):
        """(Os Authority String → C) → Machine → C"""

        def closure(value):
            match value:
                case Machine(_os=os, _auth=auth, _key=key):
                    return func(os, auth, key)
                case _:
                    Check.failed("value is not a Machine.", f"value: {value}")

        return closure

    @staticmethod
    def is_a(value) -> bool:
        """Any → Boolean

        Return true iff value is an instance of Machine
        """

        return isinstance(value, Machine)

    @staticmethod
    def check(value):
        """Any → ∅

        Raise an exception iff value is not an instance of Machine
        """
        if not Machine.is_a(value):
            Check.failed("value is not a Machine", f"value={value}")

    @staticmethod
    def os(machine: Machine) -> Osys:
        """Machine → OS

        Given a machine, return its os.
        """

        def _proc(os, auth, key):
            return os

        return Machine.elim(_proc)(machine)

    @staticmethod
    def authority(machine: Machine) -> Authority:
        """Machine → Authority

        Given a machine, return its authority.
        """

        def _proc(os, auth, key):
            return auth

        return Machine.elim(_proc)(machine)

    @staticmethod
    def key(machine: Machine) -> str:
        """Machine → String

        Given a machine, return its ed25519 host key.
        """

        def _proc(os, auth, key):
            return key

        return Machine.elim(_proc)(machine)

    @staticmethod
    def module(machine: Machine) -> Module:
        """Machine → Module

        Given a machine m, then:
        - os   :≡ Machine#os(m)
        - auth :≡ Machine#auth(m)
        - ip   :≡ Authority#ip(auth)
        - port :≡ Authority#port(auth)
        - key  :≡ Machine#key(m)

        and return a module which exports an instance of a [[ref:de72f362-d3c5-4c64-aab7-59a3d427e470][Machine]] named
        clocks:machine.

        If clocks:machine is deployed as part of a [[ref:d78940d6-33a0-4235-b094-9fa13dc27506][GuixDeployment]], then an attempt
        will be made at deploying os to the computer designated by ip on port and
        identified by key,

        """

        def _proc(os, auth, key):
            string = _MACHINE_TEMPLATE
            os_use_modules = Module.use_modules(Osys.module(os))
            string = string.replace("__OS__", os_use_modules)
            ip = Authority.ip(auth)
            string = string.replace("__IP__", Ip.string(ip))
            port = Authority.port(auth)
            string = string.replace("__PORT__", Port.string(port))
            string = string.replace("__KEY__", key)
            return Module.mk(string)

        return Machine.elim(_proc)(machine)

    @staticmethod
    def install(machine: Machine, dir: Path) -> Path:
        """Machine Directory → Path

        Given a machine and a directory dir, install machine under dir and the machine file.
        """

        def _proc(os, auth, key):
            Check.dir(dir)
            Osys.install(os, dir)
            module = Machine.module(machine)
            return Module.install(module, dir)

        return Machine.elim(_proc)(machine)
