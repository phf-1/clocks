from __future__ import annotations

from dataclasses import dataclass

from clocks.authority import Authority
from clocks.check import Check
from clocks.maybe import Maybe
from clocks.mode import Mode
from clocks.port import Port
from clocks.ip import Ip
from clocks.seq import Seq
from clocks.string import String


@dataclass(frozen=True)
class Params:
    """[[id:69ca9c93-4bfa-4c6d-90c0-f44e8ef2009a][Params]]

    a Params represents the CLI parameter inputs
    """

    _strings: list[str]

    @staticmethod
    def mk(strings: list) -> Params:
        for s in strings:
            String.check(s)
        return Params(strings)

    @staticmethod
    def is_a(x: any) -> bool:
        return isinstance(x, Params)

    @staticmethod
    def check(x: any) -> None:
        if not Params.is_a(x):
            raise ValueError(f"x is not a Params. x: {x}")

    @staticmethod
    def elim(func):
        """(List(String) → C) → Params → C"""

        def use(params: Params):
            Params.check(params)
            return func(params._strings)

        return use

    @staticmethod
    def get(params, idx):
        """Params ℕ → Maybe(String)"""
        return Params.elim(lambda strings: Seq.get(strings, idx))(params)

    @staticmethod
    def port(params: Params, idx: int) -> Maybe:
        """Params ℕ → Maybe(Port)"""
        maybe = Params.get(params, idx)
        return Maybe.lift(Port.parse)(maybe)

    @staticmethod
    def ip(params: Params, idx: int) -> Maybe:
        """Params ℕ → Maybe(Ip)"""
        maybe = Params.get(params, idx)
        return Maybe.lift(Ip.parse)(maybe)

    @staticmethod
    def mode(params: Params, idx: int) -> Mode:
        """Params ℕ → Maybe(Mode)"""
        maybe = Params.get(params, idx)
        return Maybe.lift(Mode.parse)(maybe)

    @staticmethod
    def string(params, idx):
        """Params ℕ → Maybe(String)"""
        return Params.get(params, idx)

    @staticmethod
    def authority(params, idx):
        """Params ℕ → Maybe(Authority)"""
        maybe = Params.get(params, idx)
        return Maybe.lift(Authority.parse)(maybe)

    @staticmethod
    def port_check(params: Params, idx: int) -> Maybe:
        """Params ℕ → Port"""
        maybe = Params.port(params, idx)
        if Maybe.is_nothing(maybe):
            Check.failed(
                "param at idx is not a Port",
                f"params: {params}",
                f"idx: {idx}",
            )
        else:
            return Maybe.value(maybe)

    @staticmethod
    def ip_check(params: Params, idx: int) -> Maybe:
        """Params ℕ → Ip"""
        maybe = Params.ip(params, idx)
        if Maybe.is_nothing(maybe):
            Check.failed(
                "param at idx is not a Ip",
                f"params: {params}",
                f"idx: {idx}",
            )
        else:
            return Maybe.value(maybe)

    @staticmethod
    def mode_check(params: Params, idx: int) -> Mode:
        """Params ℕ → Mode"""
        maybe = Params.mode(params, idx)
        if Maybe.is_nothing(maybe):
            Check.failed(
                "param at idx is not a Mode",
                f"params: {params}",
                f"idx: {idx}",
            )
        else:
            return Maybe.value(maybe)

    @staticmethod
    def string_check(params, idx):
        """Params ℕ → String"""
        maybe = Params.string(params, idx)
        if Maybe.is_nothing(maybe):
            Check.failed(
                "param at idx is not a String",
                f"params: {params}",
                f"idx: {idx}",
            )
        else:
            return Maybe.value(maybe)

    @staticmethod
    def authority_check(params, idx):
        """Params ℕ → Authority"""
        maybe = Params.authority(params, idx)
        if Maybe.is_nothing(maybe):
            Check.failed(
                "param at idx is not a Authority",
                f"params: {params}",
                f"idx: {idx}",
            )
        else:
            return Maybe.value(maybe)
