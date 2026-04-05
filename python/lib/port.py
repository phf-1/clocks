# Specification

# [[id:bbabbbd6-cd92-44b3-91b7-095c979f7f45][Port]]
#
# port : Port represents a port number (1 ≤ n ≤ 65535)
#
# is?   : Any → Boolean
# check : Any → Port   (validates and returns int, raises CheckError if invalid)
# number : Port → ℕ

# Implementation

from __future__ import annotations
from check import Check

class Port:
    """Represents a valid TCP/UDP port (integer from 1 to 65535)."""

    def __init__(self, value):
        try:
            n = int(value)
            if 1 <= n <= 65535:
                self._value = value
            else:
                raise ValueError
        except Exception:
            Check.failed("Cannot build a port from value", f"value={value}")
        
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

    def __str__(self):
        return str(self._value)
    
    
Port.number = Port.elim(lambda x: x)
