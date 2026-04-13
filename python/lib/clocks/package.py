from __future__ import annotations

import os
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

from clocks.check import Check
from clocks.module import Module
from clocks.fs import Fs

_PACKAGE_TEMPLATE = (Fs.python_data() / "package.scm").read_text()


# TODO(796b): use more of @dataclass
@dataclass
class Package:
    """
    [[id:fdccf5fb-f69d-4f30-9e84-13489237537c][Package]]

    A package represents a [[ref:65e6819a-31da-4ba2-a6cb-f1ee97c06020][GuixPackage]] that allows to install a [[ref:0b6d8a58-28c7-4d29-891d-b8f879659688][PhoenixDistribution]].

    Dist :≡ [[ref:0b6d8a58-28c7-4d29-891d-b8f879659688][PhoenixDistribution]]
    """

    _dist: Path
    _string: str

    def __post_init__(self):
        from clocks.guix import Guix

        self._Guix = Guix

    @staticmethod
    def mk(dist: Path) -> Package:
        """Path → Package

        Given a path p such that p ≡ …/dist is a [[ref:0b6d8a58-28c7-4d29-891d-b8f879659688][PhoenixDistribution]], then return a
        [[ref:fdccf5fb-f69d-4f30-9e84-13489237537c][Package]] that defines clocks and return it.
        """

        Check.dir(dist)
        string = _PACKAGE_TEMPLATE.replace("__DIST__", str(dist))
        return Package(dist, string)

    @staticmethod
    def elim(func):
        """(Dist String → C) → Package → C"""

        def closure(value):
            match value:
                case Package(_dist=dist, _string=string):
                    return func(dist, string)
                case _:
                    Check.failed("value is not a Package", f"value: {value}")

        return closure

    @staticmethod
    def is_a(x):
        return isinstance(x, Package)

    @staticmethod
    def check(value) -> None:
        if not Package.is_a(value):
            Check.failed("value is not a Package", f"value={value}")

    @staticmethod
    def dist(package: Package):
        """Package → Dist

        Return the distribution that this package is meant to install
        """

        def _proc(dist, string):
            return dist

        return Package.elim(_proc)(package)

    @staticmethod
    def string(package: Package):
        """Package → String

        Return a string, representation of the package
        """

        def _proc(dist, string):
            return string

        return Package.elim(_proc)(package)

    @staticmethod
    def module(package: Package):
        """Package → Module

        Given a package, return the associated module
        """

        def _proc(dist, string):
            return Module.mk(string)

        return Package.elim(_proc)(package)

    @staticmethod
    def install(package: Package, a_dir: Path) -> None:
        """Package Directory → Path

        Given a package and a directory dir, then intall the package under dir and
        return the path to the file.
        """

        def _proc(dist, string):
            Check.dir(a_dir)
            module = Package.module(package)
            return Module.install(module, a_dir)

        return Package.elim(_proc)(package)
