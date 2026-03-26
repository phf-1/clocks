# [[id:2694738f-4196-4b67-b7ea-13b79f456b9a][String]]
#
# This module augments operations on strings.
# It is named "chars" because "string" is already used somewhere in the logging module.

from check import Check

class String:
    """
    is_a : Boolean
    check : ∅
    """

    @staticmethod
    def is_a(x):
        return isinstance(x, str)

    @staticmethod
    def check(x):
        if not String.is_a(x):
            Check.failed("x is not a String", f"x: {x}")
        return x
