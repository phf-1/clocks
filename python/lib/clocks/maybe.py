from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass
class Maybe:
    """[[id:cedcd8c0-58ba-43a7-afc6-30489f5efdff][Maybe]]

    Maybe(X) represents a value of some type or the absence of it.
    """

    _present: bool
    _value: Any | None

    @staticmethod
    def nothing() -> Maybe:
        return Maybe(False, None)

    @staticmethod
    def just(value: any) -> Maybe:
        return Maybe(True, value)

    @staticmethod
    def is_a(x: any) -> bool:
        return isinstance(x, Maybe)

    @staticmethod
    def is_nothing(x: any) -> bool:
        return Maybe.is_a(x) and not x._present

    @staticmethod
    def check(value: any) -> None:
        if not Maybe.is_a(value):
            raise ValueError(f"value is not a Maybe. value: {value}")

    @staticmethod
    def elim(ifabsent, ifpresent):
        """C (X → C) → Maybe(X) → C"""

        def use(maybe: Maybe):
            Maybe.check(maybe)
            match maybe:
                case Maybe(_present=False):
                    return ifabsent
                case Maybe(_present=True, _value=v):
                    return ifpresent(v)

        return use

    @staticmethod
    def value(maybe: Maybe):
        """Maybe(X) → X | None"""
        return Maybe.elim(None, lambda x: x)(maybe)

    @staticmethod
    def lift(func):
        """(A → Maybe(B)) → Maybe(A) → Maybe(B)"""
        return lambda maybe: Maybe.elim(Maybe.nothing(), lambda a: func(a))(maybe)
