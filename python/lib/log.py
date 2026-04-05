# Specification

# [[id:24e56bb1-c07d-450c-b5a4-643834ef3d23][log]]
#
# Logging functions
#
# Logging library.
#   info "n is even"        ↦ stdout += "INFO      | n is even\n"
#   info "n is even" "n=2"  ↦ stdout += "INFO      | n is even | n=2\n"
#   error …                 ↦ stderr
#   ok …                    ↦ stdout
#   debug "x" (DEBUG=true)  ↦ stderr += "DEBUG     | x | <caller>\n"

# Implementation

from __future__ import annotations

import os
import sys
import traceback

def _log(level: str, assertion: str, *ctx: str, stderr: bool = False) -> None:
    parts = [level]
    if assertion:
        parts.append(assertion)
    parts.extend(ctx)
    msg = " | ".join(parts)
    print(msg, file=sys.stderr if stderr else sys.stdout)

# Interface

class Log:
    @staticmethod
    def info(assertion: str = "", *ctx: str) -> None:
        _log("INFO     ", assertion, *ctx)

    @staticmethod
    def objective(assertion: str = "", *ctx: str) -> None:
        _log("OBJECTIVE", assertion, *ctx)

    @staticmethod
    def ok(assertion: str = "", *ctx: str) -> None:
        _log("OK       ", assertion, *ctx)

    @staticmethod
    def todo(assertion: str = "", *ctx: str) -> None:
        _log("TODO     ", assertion, *ctx)

    @staticmethod
    def error(assertion: str = "", *ctx: str) -> None:
        caller = traceback.extract_stack()[-2].name
        _log("ERROR    ", assertion, *ctx, caller, stderr=True)

    @staticmethod
    def debug(assertion: str = "", *ctx: str) -> None:
        if os.environ.get("DEBUG") == "true":
            caller = traceback.extract_stack()[-2].name
            _log("DEBUG    ", assertion, *ctx, caller, stderr=True)
