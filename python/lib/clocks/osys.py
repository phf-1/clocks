from __future__ import annotations

from pathlib import Path
from dataclasses import dataclass, field
from clocks.check import Check
from clocks.fs import Fs
from clocks.string import String
from clocks.maybe import Maybe
from clocks.package import Package
from clocks.module import Module
import tempfile
import shutil
import re

_INIT_OS = (Fs.scheme() / "clocks" / "init-os.scm").read_text()
_DEV_OS = (Fs.python_data() / "dev-os.scm").read_text()


@dataclass
class Osys:
    """
    [[id:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]]

    An OS represents an [[ref:be4a5e39-7ec4-43ed-9d96-376db49ce782][operating systems]]. The available operating systems are: init
    dev, prod.

    The init operating system is the one we get from a fresh VPS: it is minimal and
    its only purpose is to serve as a deployment target.

    The dev operating system simulates a production deployment, but local to the
    developer machine. It allows to test the complete application as if it was
    deployed on a production VPS except for some properties like HTTPS certificates.

    The prod operating system TODO(dbf7)
    """

    _name: str
    _string: Path
    _package: Maybe

    def __post_init__(self):
        from clocks.guix import Guix

        self._Guix = Guix

    @staticmethod
    def init():
        """Osys"""
        return Osys("init", _INIT_OS, Maybe.nothing())

    @staticmethod
    def dev(pkg):
        """[[ref:fdccf5fb-f69d-4f30-9e84-13489237537c][Package]] → [[ref:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]]

        Given a package pkg, return a representation of an OS such that the
        development machine that executes it serves the application contained in pkg.

        It implies that the os provides appropriate services to the application like
        reverse proxy or database access.
        """

        Package.check(pkg)
        return Osys("dev", _DEV_OS, Maybe.just(pkg))

    @staticmethod
    def elim(func):
        """(Name String Maybe(Package)  → C) → Machine → C"""

        def closure(value):
            match value:
                case Osys(_name=name, _string=string, _package=package):
                    return func(name, string, package)
                case _:
                    Check.failed("value is not a Osys.", f"value: {value}")

        return closure

    @staticmethod
    def is_a(value) -> bool:
        """Any → Boolean

        Return true iff value is an instance of Osys
        """

        return isinstance(value, Osys)

    @staticmethod
    def check(value):
        """Any → ∅

        Raise an exception iff value is not an instance of Osys
        """
        if not Osys.is_a(value):
            Check.failed("value is not a Osys", f"value={value}")

    @staticmethod
    def name(osys: Osys) -> str:
        """Osys → String

        Given a osys, return its name
        """

        def _proc(name, string, package):
            return name

        return Osys.elim(_proc)(osys)

    @staticmethod
    def string(osys: Osys) -> str:
        """Osys → String

        Given a osys, return its string
        """

        def _proc(name, string, package):
            return string

        return Osys.elim(_proc)(osys)

    @staticmethod
    def package(osys: Osys) -> str:
        """Osys → Maybe(Package)

        Given a osys, return its package, if any
        """

        def _proc(name, string, package):
            return package

        return Osys.elim(_proc)(osys)

    @staticmethod
    def module(osys: Osys) -> str:
        """Osys → Module

        Given an os, return its module
        """

        def _proc(name, string, package):
            return Module.mk(string)

        return Osys.elim(_proc)(osys)

    @staticmethod
    def install(osys: Osys, dir: Path) -> Path:
        """Osys Directory → Path

        Given an os and a directory dir, then intall os under dir and return the path
        to the file.
        """

        def _proc(name, string, package):
            Check.dir(dir)
            if Maybe.is_just(package):
                pkg = Maybe.value(package)
                Package.install(pkg, dir)
            module = Osys.module(osys)
            return Module.install(module, dir)

        return Osys.elim(_proc)(osys)
