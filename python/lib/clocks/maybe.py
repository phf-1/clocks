from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Generic, TypeVar

A = TypeVar("A")


@dataclass
class Maybe(Generic[A]):
    """[[id:cedcd8c0-58ba-43a7-afc6-30489f5efdff][Maybe]]

    Maybe(X) represents a value of some type or the absence of it.
    """

    _present: bool
    _value: Any

    @staticmethod
    def nothing():
        """→ Maybe(Nothing)"""
        return Maybe(_present=False, _value=None)

    @staticmethod
    def just(value):
        """A → Maybe(A)"""
        return Maybe(_present=True, _value=value)

    @staticmethod
    def is_a(x, inner_type=None):
        """Object [Type] → Boolean"""
        if isinstance(x, Maybe):
            if x._present:
                if inner_type:
                    return isinstance(x._value, inner_type)
                else:
                    return True
            else:
                return True
        else:
            return False

    @staticmethod
    def is_nothing(x):
        """Maybe(X) → Boolean"""
        return not x._present  # noqa: SLF001

    @staticmethod
    def is_just(x):
        """Maybe(X) → Boolean"""
        return x._present  # noqa: SLF001

    @staticmethod
    def check(value, inner_type=None):
        """Object → None"""
        if not Maybe.is_a(value, inner_type):
            msg = f"value is not a Maybe. value: {value}"
            raise ValueError(msg)

    @staticmethod
    def elim(ifabsent, ifpresent):
        """C (X → C) → Maybe(X) → C"""

        def use(maybe):
            Maybe.check(maybe)
            match maybe:
                case Maybe(_present=False):
                    return ifabsent
                case Maybe(_present=True, _value=v):
                    return ifpresent(v)
                case _:
                    pass
            msg = f"unreachable: {maybe}"
            raise ValueError(msg)

        return use

    @staticmethod
    def value(maybe):
        """Maybe(X) → X | None"""
        return Maybe.elim(None, lambda x: x)(maybe)

    @staticmethod
    def lift(func):
        """(A → Maybe(B)) → Maybe(A) → Maybe(B)"""
        return lambda maybe: Maybe.elim(Maybe.nothing(), func)(maybe)
