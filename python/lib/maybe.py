# [[id:cedcd8c0-58ba-43a7-afc6-30489f5efdff][Maybe]]
#
# Maybe(X) represents a value of some type or the absence of it.

from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Optional

@dataclass
class Maybe:
    """
    nothing : Maybe(X)
    just : X → Maybe(X)
    elim : C (X → C) → Maybe(X) → C
    value : Maybe(X) → X | None
    """

    _present: bool
    _value: Optional[Any]

    @staticmethod
    def nothing() -> Maybe:
        return Maybe(False, None)

    @staticmethod
    def just(value) -> Maybe:
        return Maybe(True, value)

    @staticmethod
    def is_a(x) -> bool:
        return isinstance(x, Maybe)

    @staticmethod
    def check(x) -> None:
        if not Maybe.is_a(x):
            raise ValueError(f"x is not a Maybe. x: {x}")

    @staticmethod
    def elim(ifabsent, ifpresent):
        def use(maybe: "Maybe"):
            Maybe.check(maybe)
            match maybe:
                case Maybe(_present=False, _value=None):
                    return ifabsent
                case Maybe(_present=True, _value=v):
                    return ifpresent(v)
        return use

    @staticmethod
    def value(maybe):
        return Maybe.elim(None, lambda x: x)(maybe)
