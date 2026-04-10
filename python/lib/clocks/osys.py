# [[id:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]]
#
# os : OS represents an [[ref:be4a5e39-7ec4-43ed-9d96-376db49ce782][OS]]

from __future__ import annotations

import re

from clocks.check import Check
from clocks.fs import Fs

_SCHEME_VM = Fs.root() / "scheme" / "app" / "vm"
Check.dir(_SCHEME_VM)


def _parse_define_module(path: str) -> str | None:
    with open(path, encoding="utf-8") as f:
        text = f.read()
    m = re.search(r"\(define-module\s+(\([^)]+\))", text)
    return m.group(1) if m else None


class Osys:
    """init : OS
    dev : OS
    name : OS → String
    spec : OS → Path
    use_modules : OS → String
    """

    def __init__(self, name):
        self._name = name
        self._spec = spec = _SCHEME_VM / name / "os.scm"
        spec.is_file() or Check.failed("name does not match an os.scm", f"name: {name}")

    def __str__(self):
        return f"Osys.mk(name: {Osys.name(self)})"

    @staticmethod
    def mk(name):
        return Osys(name)

    @staticmethod
    def init():
        return Osys("init")

    @staticmethod
    def dev():
        return Osys("dev")

    @staticmethod
    def is_a(x):
        return isinstance(x, Osys)

    @staticmethod
    def check(value) -> None:
        if not Osys.is_a(value):
            Check.failed("value is not an OS", f"value={value}")

    @staticmethod
    def elim(func):
        def closure(osys):
            Osys.check(osys)
            return func(osys._name, osys._spec)

        return closure

    @staticmethod
    def name(osys):
        return Osys.elim(lambda name, _spec: name)(osys)

    @staticmethod
    def spec(osys):
        return Osys.elim(lambda _name, spec: spec)(osys)

    @staticmethod
    def use_modules(osys):
        coordinates = _parse_define_module(Osys.spec(osys))
        return f"(use-modules {coordinates})"
