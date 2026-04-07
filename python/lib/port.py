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
from check import Check

# Interface

class Port:
    """Represents a valid TCP/UDP port (integer from 1 to 65535)."""

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
    def number(port) -> int:
        return Port.elim(lambda value: value)(port)
