from __future__ import annotations
from dataclasses import dataclass
from clocks.check import Check
from clocks.maybe import Maybe
from clocks.string import String


@dataclass(frozen=True)
class Port:
    """
    [[id:bbabbbd6-cd92-44b3-91b7-095c979f7f45][Port]]

    a Port represents a port number
    """

    _value: int

    def __str__(self):
        return str(self._value)

    @staticmethod
    def mk(value) -> Port:
        """n:ℕ (1 ≤ n ≤ 65535) → Port"""
        n = int(value)
        if 1 <= n <= 65535:
            return Port(value)
        else:
            Check.failed("Cannot build a port from value", f"value={value}")

    @staticmethod
    def is_a(value) -> bool:
        return isinstance(value, Port)

    @staticmethod
    def check(value) -> int:
        if not Port.is_a(value):
            Check.failed("value is not a Port", f"value={value}")

    @staticmethod
    def elim(func):
        """(ℕ → C) → Port → C"""

        def closure(port):
            Port.check(port)
            return func(port._value)

        return closure

    @staticmethod
    def int(port: Port) -> int:
        return Port.elim(lambda value: value)(port)

    @staticmethod
    def string(port: Port) -> str:
        return Port.elim(str)(port)

    @staticmethod
    def parse(value: str) -> Maybe:
        """String → Maybe(Port)"""
        String.check(value)
        try:
            port = Port.mk(value)
            return Maybe.just(port)
        except Exception:
            return Maybe.nothing()
