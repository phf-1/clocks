from __future__ import annotations
from dataclasses import dataclass
from clocks.check import Check
from clocks.string import String
from clocks.fs import Fs
from clocks.string import String
from clocks.authority import Authority
import re


def _parse_define_module(s: str) -> list[str]:
    match = re.search(r"\(define-module\s+\(([^)]+)\)", s)
    if not match:
        Check.failed(
            "There is no (define-modules (…)) form in string.", f"string: {string}"
        )
    return match.group(1).split()


@dataclass
class Module:
    """
    [[id:bec5386b-3923-409e-8905-1c2ddd5e8cb5][Module]]

    A module is a representation of a [[ref:818ad4b0-1363-437a-a4e0-3489dcee40a3][Module]].
    """

    _id: list
    _string: str

    @staticmethod
    def mk(string: str) -> Module:
        """String → Module

        Given a string s, return an instance of [[ref:bec5386b-3923-409e-8905-1c2ddd5e8cb5][Module]].
        """

        String.check(string)
        return Module(_parse_define_module(string), string)

    @staticmethod
    def elim(func):
        """(List(String) String → C) → Module → C"""

        def closure(value):
            match value:
                case Module(_id=id, _string=string):
                    return func(id, string)
                case _:
                    Check.failed("value is not a Module.", f"value: {value}")

        return closure

    @staticmethod
    def is_a(value) -> bool:
        """Any → Boolean

        Return true iff value is an instance of Module
        """

        return isinstance(value, Module)

    @staticmethod
    def check(value):
        """Any → ∅

        Raise an exception iff value is not an instance of Module
        """
        if not Module.is_a(value):
            Check.failed("value is not a Module", f"value={value}")

    @staticmethod
    def id(module: Module) -> list:
        """Module → List(String)

        Given a module, return list of strings that represents the module name.

        Example: ["alice", "hello", "world"]
        """

        def _proc(id, string):
            return id

        return Module.elim(_proc)(module)

    @staticmethod
    def string(module: Module) -> str:
        """Module → String

        Given a module, return its definition as a string.
        """

        def _proc(id, string):
            return string

        return Module.elim(_proc)(module)

    @staticmethod
    def use_modules(module: Module) -> str:
        """Module → String

        Given a module, return use-modules string.

        Example: (use-modules (alice hello world))
        """

        id = Module.id(module)
        return "(use-modules" + "(" + " ".join(id) + ")" + ")"

    @staticmethod
    def install(module: Module, dir: Path) -> str:
        """Module Directory → Path

        Given a module and a directory dir, install the module under dir then return
        the file that has been created.
        """

        def _proc(id, string):
            Check.dir(dir)
            parent = dir
            for name in id[:-1]:
                parent = parent / name
                parent.mkdir(exist_ok=True)
                file = parent / f"{id[-1]}.scm"
            with open(file, mode="w") as f:
                f.write(string)
            return file

        return Module.elim(_proc)(module)
