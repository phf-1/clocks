from __future__ import annotations

from dataclasses import dataclass

from clocks.check import Check
from clocks.ip import Ip
from clocks.maybe import Maybe
from clocks.port import Port
from clocks.string import String


@dataclass(frozen=True)
class Authority:
    """[[id:bc2ba6d9-0f9f-40f0-af70-5fa80b9ee0ba][Authority]]

    Represents an [[ref:56eb52ec-d0e8-4f03-8199-9ca69887c0c5][Authority]]
    """

    _ip: Ip
    _port: Port

    def __post_init__(self) -> None:
        Ip.check(self._ip)
        Port.check(self._port)

    def __str__(self) -> str:
        return Authority.string(self)

    @staticmethod
    def mk(ip: Ip, port: Port) -> Authority:
        return Authority(ip, port)

    @staticmethod
    def is_a(value: any) -> bool:
        return isinstance(value, Authority)

    @staticmethod
    def check(value: any) -> None:
        if not Authority.is_a(value):
            Check.failed("value is not an Authority", f"value: {value}")

    @staticmethod
    def elim(func):
        """(Ip Port → C) → Authority → C"""

        def closure(authority: Authority):
            Authority.check(authority)
            return func(authority._ip, authority._port)

        return closure

    @staticmethod
    def ip(authority: Authority) -> Ip:
        return Authority.elim(lambda ip, port: ip)(authority)

    @staticmethod
    def port(authority: Authority) -> Ip:
        return Authority.elim(lambda ip, port: port)(authority)

    @staticmethod
    def string(authority: Authority) -> str:
        return Authority.elim(lambda ip, port: f"{ip}:{port}")(authority)

    @staticmethod
    def parse(value: str) -> Maybe:
        """String -> Maybe(Authority)"""
        String.check(value)
        try:
            left, right = value.split(":", 1)
            maybe_ip = Ip.parse(left)
            if Maybe.is_nothing(maybe_ip):
                return maybe_ip
            maybe_port = Port.parse(right)
            if Maybe.is_nothing(maybe_port):
                return maybe_port
            authority = Authority.mk(Maybe.value(maybe_ip), Maybe.value(maybe_port))
            return Maybe.just(authority)
        except Exception:
            return Maybe.nothing()
