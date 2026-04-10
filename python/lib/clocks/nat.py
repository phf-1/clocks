from __future__ import annotations
from clocks.check import Check
from clocks.string import String
from clocks.maybe import Maybe


class Nat:
    """
    [[id:33ebb50a-8871-46f5-a8f4-499282442495][Nat]]

    a Nat represents a natural number
    """

    def __init__(self, value):
        self._value = value

    def __str__(self):
        return str(self._value)

    @staticmethod
    def mk(value: int) -> Nat:
        Check.int(value)
        if not value >= 0:
            Check.failed("Cannot build a Nat from value", f"value: {value}")
        return Nat(value)

    @staticmethod
    def is_a(value: any) -> bool:
        return isinstance(value, Nat)

    @staticmethod
    def check(value: any) -> None:
        if not Nat.is_a(value):
            Check.failed("value is not a Nat", f"value={value}")

    @staticmethod
    def elim(func):
        """(Int → C) → Nat → C"""

        def closure(nat):
            Nat.check(nat)
            return func(nat._value)

        return closure

    @staticmethod
    def int(nat: Nat) -> int:
        return Nat.elim(lambda value: value)(nat)

    @staticmethod
    def string(nat: Nat) -> str:
        return Nat.elim(str)(nat)

    @staticmethod
    def parse(value):
        """String → Maybe(Nat)"""
        String.check(value)
        try:
            nat = Nat.mk(int(value))
            return Maybe.just(nat)
        except Exception:
            return Maybe.nothing()
