from __future__ import annotations

import logging
import os
import traceback
from pathlib import Path

OBJECTIVE: int = 25
OK: int = 26
TODO: int = 27

logging.addLevelName(OBJECTIVE, "OBJECTIVE")
logging.addLevelName(OK, "OK       ")
logging.addLevelName(TODO, "TODO     ")
logging.addLevelName(logging.DEBUG, "DEBUG    ")
logging.addLevelName(logging.INFO, "INFO     ")
logging.addLevelName(logging.ERROR, "ERROR    ")


def _caller_chain(max_frames: int = 4) -> str:
    """Integer → String"""
    stack = traceback.extract_stack()
    chain: list[str] = []
    for frame in reversed(stack[:-3]):
        filename = frame.filename
        if filename.endswith("/log.py") or "/logging/" in filename:
            continue
        short_file = Path(filename).name
        # chain.append(f"{short_file}:{frame.lineno} {frame.name}")
        chain.append(f"{short_file}#{frame.name}")
        if len(chain) >= max_frames:
            break
    return " ← ".join(chain) if chain else "<unknown>"


class _PipeFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        """LogRecord → String"""
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


class Log:
    r"""[[id:24e56bb1-c07d-450c-b5a4-643834ef3d23][Log]]

    This module provides logging function.

    info "n is even"        ↦ stdout += "INFO      | n is even\n"
    info "n is even" "n=2"  ↦ stdout += "INFO      | n is even | n=2\n"
    error …                 ↦ stderr  + caller chain
    debug …                 ↦ (when DEBUG=true) stderr + caller chain
    …
    """

    @staticmethod
    def info(assertion: str = "", *ctx: str) -> None:
        """String List(String) → info message printed to stdout"""
        _logger.info(_msg(assertion, *ctx))

    @staticmethod
    def objective(assertion: str = "", *ctx: str) -> None:
        """String List(String) → objective message printed to stdout"""
        _logger.log(OBJECTIVE, _msg(assertion, *ctx))

    @staticmethod
    def ok(assertion: str = "", *ctx: str) -> None:
        """String List(String) → ok message printed to stdout"""
        _logger.log(OK, _msg(assertion, *ctx))

    @staticmethod
    def todo(assertion: str = "", *ctx: str) -> None:
        """String List(String) → todo message printed to stdout"""
        _logger.log(TODO, _msg(assertion, *ctx))

    @staticmethod
    def error(assertion: str = "", *ctx: str) -> None:
        """String List(String) → error message printed to stderr"""
        caller = _caller_chain()
        _logger.error(_msg(assertion, *ctx, caller))

    @staticmethod
    def debug(assertion: str = "", *ctx: str) -> None:
        """String List(String) → debug message (only when DEBUG=true)"""
        if os.environ.get("DEBUG") == "true":
            caller = _caller_chain()
            _logger.debug(_msg(assertion, *ctx, caller))
