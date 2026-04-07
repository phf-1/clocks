# python/lib/ip.py
# Specification

# [[id:2e06869b-d68d-4683-a3e6-84357b245e3d][Ip]]
#
# ip : Ip represents an IPv4 address
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))
# string : Ip → String

# Implementation

from __future__ import annotations
import re

from check import Check

_RE = re.compile(r"^([0-9]{1,3}\.){3}[0-9]{1,3}$")

# Interface

class Ip:
    def __init__(self, value):
        if not _RE.match(value):
            Check.failed("ip is not an Ip", f"ip={value}")
        self._value = value

    def __str__(self):
        return self._value

    @staticmethod
    def parse(value):
        try:
            return Ip(value)
        except Exception:
            return None

    @staticmethod
    def is_a(value):
        return isinstance(value, Ip)

    @staticmethod
    def check(value: str) -> None:
        if not Ip.is_a(value):
            Check.failed("ip is not a Ip", f"ip={value}")

    @staticmethod
    def elim(func):
        def closure(ip):
            Ip.check(ip)
            return func(ip._value)
        return closure

    @staticmethod
    def string(ip):
        return Ip.elim(lambda value: value)(ip)
