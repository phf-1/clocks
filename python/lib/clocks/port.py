# Specification

# [[id:bbabbbd6-cd92-44b3-91b7-095c979f7f45][Port]]
#
# a Port represents a port number
#
# Port : n:ℕ (1 ≤ n ≤ 65535) → Port
# is_a   : Any → Boolean
# check : Any → Maybe(Error)
# elim : (ℕ → C) → Port → C
# number : Port → ℕ

# Implementation

from __future__ import annotations
from clocks.check import Check
from clocks.string import String
from clocks.maybe import Maybe

# Interface

class Port:
    """
    [[id:c4a3e737-ebd1-4922-b57e-2f135880d3e9][Port]]

    Represents a [[ref:26ba86e3-8472-48b7-9701-00313fa7a030][Port]]
    """

    def __init__(self, value):
        try:
            n = int(value)
            if 1 <= n <= 65535:
                self._value = n
            else:
                raise ValueError
        except Exception:
            Check.failed("Cannot build a port from value", f"value={value}")

    def __str__(self):
        return str(self._value)

    @staticmethod
    def mk(value) -> "Port":
        return Port(value)

    @staticmethod
    def is_a(value) -> bool:
        """Check whether a value is a valid port number."""
        return isinstance(value,Port)

    @staticmethod
    def check(value) -> int:
        if not Port.is_a(value):
            Check.failed("value is not a Port", f"value={value}")

    @staticmethod
    def elim(func):
        def closure(port):
            Port.check(port)
            return func(port._value)
        return closure

    @staticmethod
    def int(port) -> int:
        return Port.elim(lambda value: value)(port)

    @staticmethod
    def string(port: Port) -> str:
        return Port.elim(str)(port)

    @staticmethod
    def parse(value):
        """String → Maybe(Port)"""
        String.check(value)
        try:
            port = Port.mk(value)
            return Maybe.just(port)
        except Exception:
            return Maybe.nothing()
