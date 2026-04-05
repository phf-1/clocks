# Specification

# [[id: mirrors bash/lib/check.bash]]
#
# failed_check "msg" "ctx…" ⇒ log an error and exit 1.
# dir_check, file_check, exist_check, nat_check, cmd_check, …

# Implementation

from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

from log import Log
error = Log.error

class _CheckError(SystemExit):
    """Raised by failed_check. Extends SystemExit so it exits with code 1
    without needing an explicit sys.exit at every call site."""
    def __init__(self, msg: str, *ctx: str) -> None:
        error(msg, *ctx)
        super().__init__(1)

# Interface

class Check:
    @staticmethod
    def failed(msg: str, *ctx: str) -> None:
        raise _CheckError(msg, *ctx)

    @staticmethod
    def not_implemented() -> None:
        Check.failed("Not implemented")

    @staticmethod
    def dir(value: str | Path) -> None:
        if not Path(value).is_dir():
            Check.failed("value is not a directory", f"value={value}")

    @staticmethod
    def file(value: str | Path) -> None:
        if not Path(value).is_file():
            Check.failed("value is not a regular file", f"value={value}")

    @staticmethod
    def exist(value: str | Path) -> None:
        if not Path(value).exists():
            Check.failed("path is not in the filesystem", f"path={value}")

    @staticmethod
    def value_in(value: str, *allowed: str) -> None:
        if value not in allowed:
            Check.failed("value is not allowed",
                         f"value={value}",
                         f"allowed={' '.join(allowed)}")

    @staticmethod
    def nat(value: str | int) -> None:
        # TODO(3a16): should not start by 0.
        if not re.fullmatch(r"[0-9]+", str(value)):
            Check.failed("value does not represent a ℕ", f"value={value}")

    @staticmethod
    def cmd(cmd: str) -> None:
        if shutil.which(cmd) is None:
            Check.failed("value is not a command", f"value={cmd}")

    @staticmethod
    def file_in_dir_pred(file: str | Path, directory: str | Path) -> bool:
        f = Path(file).resolve()
        d = Path(directory).resolve()
        if not f.exists() or not d.is_dir():
            return False
        return str(f).startswith(str(d) + os.sep)

    @staticmethod
    def file_in_dir(file: str | Path, directory: str | Path) -> None:
        f = Path(file).resolve()
        Check.exist(f)
        d = Path(directory).resolve()
        dir(d)
        if not Check.file_in_dir_pred(f, d):
            Check.failed("file ∉ dir", f"file={f}", f"dir={d}")
