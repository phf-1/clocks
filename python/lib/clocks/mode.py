# [[id:9498f31c-91da-4a26-85a7-e0fad70bedff][Mode]]
#
# m : Mode represents the category of users using the application, developers,
# automated systems for testing purposes, paying customers.

# Implementation

from __future__ import annotations
from clocks.check import Check
from clocks.maybe import Maybe
from clocks.string import String

_VALUES = ("dev", "test", "prod")

# Interface


class Mode:
    """
    dev : Mode
    test : Mode
    prod : Mode
    elim : C C C → Mode → C
    """

    def __init__(self, value):
        if value not in _VALUES:
            Check.failed(
                "value not in _VALUES", f"value: {value}", f"_VALUES: {_VALUES}"
            )
        self._value = value

    def __eq__(self, x):
        return Mode.is_a(x) and self._value == x._value

    def __str__(self):
        return self._value

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
            if mode._value == "dev":
                return ifdev
            if mode._value == "test":
                return iftest
            if mode._value == "prod":
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
        raise Maybe.nothing()

    @staticmethod
    def string(mode):
        return Mode.elim("dev", "test", "prod")(mode)
