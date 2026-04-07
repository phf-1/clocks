# Specification

# [[id:5517b93a-1383-47a9-8cf9-2c8494b75bfa][Result]]
#
# Result(X) represents a value that is either a success (Ok) or a failure (Err).
#
# ok  : X         → Result(X)
# err : Exception → Result(X)
# elim : (X → C) → (Exception → C) → Result(X) → C

# Implementation

from dataclasses import dataclass

@dataclass
class _Ok[X]:
    value: X

@dataclass
class _Err:
    error: Exception

# Interface

@dataclass
class Result[X]:
    _inner: _Ok[X] | _Err

    @staticmethod
    def ok(value: X) -> "Result[X]":
        return Result(_Ok(value))

    @staticmethod
    def err(error: Exception) -> "Result[X]":
        return Result(_Err(error))

    @staticmethod
    def elim(ifok, iferr):
        def use(result: "Result[X]"):
            Result.check(result)
            match result._inner:
                case _Ok(value=v):
                    return ifok(v)
                case _Err(error=e):
                    return iferr(e)
                case _:
                    raise ValueError(f"Unexpected inner type: {result._inner}")
        return use

    @staticmethod
    def is_a(x) -> bool:
        return isinstance(x, Result)

    @staticmethod
    def check(x) -> None:        
        if not Result.is_a(x):
            raise ValueError(f"x is not a Result. x: {x}")
