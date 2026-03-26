# [[id:69ca9c93-4bfa-4c6d-90c0-f44e8ef2009a][Params]]
#
# a Params represents the CLI parameter inputs

from __future__ import annotations
from dataclasses import dataclass
from seq import Seq
from maybe import Maybe
from port import Port
from mode import Mode

@dataclass(frozen=True)
class Params:
    """
    Index :≡ ℕ
    mk : List(String) → Params
    elim : (List(String) → C) → Params → C
    get : Params Index → String | None
    port : Params Index → Port
    mode : Params Index → Mode
    """

    _strings: list[str]

    @staticmethod
    def mk(strings) -> Params:
        return Params(strings)

    @staticmethod
    def is_a(x) -> bool:
        return isinstance(x, Params)

    @staticmethod
    def check(x) -> None:
        if not Params.is_a(x):
            raise ValueError(f"x is not a Params. x: {x}")

    @staticmethod
    def elim(func):
        def use(params: Params):
            Params.check(params)
            return func(params._strings)
        return use

    @staticmethod
    def get(params, idx):
        maybe = Params.elim(lambda strings: Seq.get(strings, idx))(params)
        return Maybe.value(maybe)

    @staticmethod
    def port(params, idx):
        return Port.mk(Params.get(params, idx))

    @staticmethod
    def mode(params, idx):
        return Mode.parse(Params.get(params, idx))
