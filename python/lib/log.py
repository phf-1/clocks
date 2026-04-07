# Specification

# [[id:24e56bb1-c07d-450c-b5a4-643834ef3d23][Log]]
#
# This module provides logging function.
#
# info "n is even"        ↦ stdout += "INFO      | n is even\n"
# info "n is even" "n=2"  ↦ stdout += "INFO      | n is even | n=2\n"
# error …                 ↦ stderr
# ok …                    ↦ stdout
# debug "x"               ↦ if DEBUG = true, then: stderr += "DEBUG     | x | <callers>\n"
# …

# Implementation

from __future__ import annotations

import logging
import os
import traceback

# Custom level numbers
logging.OBJECTIVE = 25
logging.OK = 26
logging.TODO = 27
logging.addLevelName(logging.OBJECTIVE, "OBJECTIVE")
logging.addLevelName(logging.OK,        "OK       ")
logging.addLevelName(logging.TODO,      "TODO     ")

# Pad built-in level names to align with custom ones
logging.addLevelName(logging.DEBUG,    "DEBUG    ")
logging.addLevelName(logging.INFO,     "INFO     ")
logging.addLevelName(logging.ERROR,    "ERROR    ")


class _PipeFormatter(logging.Formatter):
    """Formats records as: LEVEL | message (newlines collapsed to spaces)."""

    def format(self, record: logging.LogRecord) -> str:
        level = self.formatTime(record) if self.usesTime() else record.levelname
        level = record.levelname
        msg = record.getMessage().replace("\n", " ")
        return f"{level} | {msg}"


def _make_logger() -> logging.Logger:
    logger = logging.getLogger("log")
    logger.setLevel(logging.DEBUG)
    logger.propagate = False

    fmt = _PipeFormatter()

    stdout_handler = logging.StreamHandler(stream=__import__("sys").stdout)
    stdout_handler.setFormatter(fmt)
    # Emit everything below ERROR to stdout
    stdout_handler.addFilter(lambda r: r.levelno < logging.ERROR)
    stdout_handler.setLevel(logging.DEBUG)

    stderr_handler = logging.StreamHandler()
    stderr_handler.setFormatter(fmt)
    stderr_handler.setLevel(logging.ERROR)

    logger.addHandler(stdout_handler)
    logger.addHandler(stderr_handler)
    return logger


_logger = _make_logger()


def _msg(assertion: str, *ctx: str) -> str:
    parts = [assertion] if assertion else []
    parts.extend(ctx)
    return " | ".join(parts)

# Interface

class Log:
    @staticmethod
    def info(assertion: str = "", *ctx: str) -> None:
        _logger.info(_msg(assertion, *ctx))

    @staticmethod
    def objective(assertion: str = "", *ctx: str) -> None:
        _logger.log(logging.OBJECTIVE, _msg(assertion, *ctx))

    @staticmethod
    def ok(assertion: str = "", *ctx: str) -> None:
        _logger.log(logging.OK, _msg(assertion, *ctx))

    @staticmethod
    def todo(assertion: str = "", *ctx: str) -> None:
        _logger.log(logging.TODO, _msg(assertion, *ctx))

    @staticmethod
    def error(assertion: str = "", *ctx: str) -> None:
        caller = traceback.extract_stack()[-2].name
        _logger.error(_msg(assertion, *ctx, caller))

    @staticmethod
    def debug(assertion: str = "", *ctx: str) -> None:
        if os.environ.get("DEBUG") == "true":
            caller = traceback.extract_stack()[-2].name
            _logger.debug(_msg(assertion, *ctx, caller))
