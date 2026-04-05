# Specification

# [[id:9498f31c-91da-4a26-85a7-e0fad70bedff][Mode]]
#
# m : Mode represents the category of users using the application.
# dev  — developers
# test — automated systems for testing purposes
# prod — paying clients
#
# is?   : Any → Boolean
# check : Any → Maybe(Error ∧ exit 1)
# elim : ( → C) ( → C) ( → C) → Mode → C

# Implementation

from __future__ import annotations
from check import Check
from enum import Enum

# Interface

class Mode(Enum):
    dev = "dev"
    test = "test"
    prod = "prod"

    @staticmethod
    def elim(ifdev, iftest, ifprod):
        def closure(mode):
            Mode.check(mode)
            match mode:
                case Mode.dev:
                    return ifdev()
                case Mode.test:
                    return iftest()
                case Mode.prod:
                    return ifprod()
        return closure

    @staticmethod    
    def parse(s):
        if s == "dev":
            return Mode.dev
        if s == "test":
            return Mode.test
        if s == "prod":
            return Mode.prod
        Check.failed("value is not a mode", f"value: {s}")
        
    @staticmethod
    def is_a(value):
        return isinstance(value, Mode)

    @staticmethod    
    def check(value):
        if not Mode.is_a(value):
            Check.failed("value is not a mode", f"value: {value}")

    def __str__(self):
        return self.value
        

