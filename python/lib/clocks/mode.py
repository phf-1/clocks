# [[id:9498f31c-91da-4a26-85a7-e0fad70bedff][Mode]]
#
# m : Mode represents the category of users using the application, developers,
# automated systems for testing purposes, paying customers.

# Implementation

from __future__ import annotations

from dataclasses import dataclass

from clocks.check import Check
from clocks.maybe import Maybe
from clocks.string import String

_VALUES = ("dev", "test", "prod")


@dataclass(frozen=True)
class Mode:
    """
    [[id:06a72258-237c-4cc0-9171-64af1b06c0cb][Mode]]

    A mode represents the context in which the application is run. Depending on the
    context the application should behave differently.

    For instance, in dev mode, the application might return error logs to the user
    because users are developers, but not in production mode since users are
    customers.
    """

    value: str

    def __post_init__(self):
        if self.value not in _VALUES:
            Check.failed(
                "value not in _VALUES",
                f"value: {self.value}",
                f"_VALUES: {_VALUES}",
            )

    def __str__(self):
        return self.value

    @staticmethod
    def dev():
        return Mode("dev")

    @staticmethod
    def test():
        return Mode("test")

    @staticmethod
    def prod():
        return Mode("prod")

    @staticmethod
    def is_a(value):
        return isinstance(value, Mode)

    @staticmethod
    def check(value):
        if not Mode.is_a(value):
            Check.failed("value is not a Mode", f"value: {value}")

    @staticmethod
    def elim(ifdev, iftest, ifprod):
        def closure(mode):
            Mode.check(mode)
            if mode.value == "dev":
                return ifdev
            if mode.value == "test":
                return iftest
            if mode.value == "prod":
                return ifprod

        return closure

    @staticmethod
    def parse(string: str) -> Maybe:
        String.check(string)
        if string == "dev":
            return Maybe.just(Mode.dev())
        if string == "test":
            return Maybe.just(Mode.test())
        if string == "prod":
            return Maybe.just(Mode.prod())
        return Maybe.nothing()

    @staticmethod
    def string(mode):
        return Mode.elim("dev", "test", "prod")(mode)
