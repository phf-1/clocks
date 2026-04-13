from __future__ import annotations
from dataclasses import dataclass
from clocks.check import Check
from clocks.string import String


@dataclass(frozen=True)
class Message:
    """
    [[id:1176ae0d-700d-4f72-8189-30198f45c1f3][Message]]

    Message :≡ String × List(Param)
    Param :≡ Any

    Example:
      - msg :≡ Message#mk("hello name", "Alice")
      - msg#prop() = \"hello name\"
      - msg#params() = <\"Alice\">
    """

    _prop: str
    _params: tuple

    @staticmethod
    def mk(prop: str, *params: list) -> Message:
        """String List(Any) → Message"""
        String.check(prop)
        return Message(prop, params)

    @staticmethod
    def elim(func):
        """(String Param* → C) → Message → C"""

        def closure(value):
            match value:
                case Message(_prop=prop, _params=params):
                    return func(prop, *params)
                case _:
                    Check.failed("value is not a message.", f"value: {value}")

        return closure

    @staticmethod
    def is_a(value) -> bool:
        return isinstance(value, Message)

    @staticmethod
    def check(value) -> None:
        if not Message.is_a(value):
            Check.failed("value is not a Message", f"value={value}")

    @staticmethod
    def prop(message: Message) -> str:
        return Message.elim(lambda prop, *params: prop)(message)

    @staticmethod
    def params(message: Message) -> tuple:
        return Message.elim(lambda prop, *params: params)(message)
