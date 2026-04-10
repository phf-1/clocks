from __future__ import annotations

import os
import shutil
from pathlib import Path

from clocks.log import Log


class CheckError(Exception):
    """Raised by Check.failed().

    The error message has already been logged via Log.error().
    The top-level script catches this exception and exits with code 1.
    """


class Check:
    """[[id:eb549c90-fd23-45b5-b223-bcb02d28b543][Check]]

    failed_check "msg" "ctx…" ⇒ log an error and exit 1.
    dir_check, file_check, exist_check, nat_check, cmd_check, …
    """

    @staticmethod
    def failed(msg: str, *ctx: str) -> None:
        """Log error message (via Log.error) and raise CheckError to exit(1)."""
        Log.error(msg, *ctx)
        raise CheckError(msg)

    @staticmethod
    def not_implemented() -> None:
        """Fail the check with a generic 'Not implemented' error."""
        Check.failed("Not implemented")

    @staticmethod
    def dir(value: str | Path) -> None:
        """Ensure the given path is an existing directory."""
        if not Path(value).is_dir():
            Check.failed("value is not a directory", f"value: {value}")

    @staticmethod
    def int(value: object) -> None:
        """Ensure the value is an integer."""
        if not isinstance(value, int):
            Check.failed("value is not an Integer", f"value: {value}")

    @staticmethod
    def bool(value: object) -> None:
        """Ensure the value is a boolean."""
        if not isinstance(value, bool):
            Check.failed("value is not a Boolean", f"value: {value}")

    @staticmethod
    def file(value: str | Path) -> None:
        """Ensure the given path is an existing regular file."""
        if not Path(value).is_file():
            Check.failed("value is not a regular file", f"value: {value}")

    @staticmethod
    def exist(value: str | Path) -> None:
        """Ensure the given path exists in the filesystem."""
        if not Path(value).exists():
            Check.failed("path is not in the filesystem", f"path={value}")

    @staticmethod
    def value_in(value: str, *allowed: str) -> None:
        """Ensure the value is one of the allowed strings."""
        if value not in allowed:
            Check.failed(
                "value is not allowed",
                f"value: {value}",
                f"allowed: {' '.join(allowed)}",
            )

    @staticmethod
    def cmd(cmd: str) -> None:
        """Ensure the given command exists in $PATH (shutil.which succeeds)."""
        if shutil.which(cmd) is None:
            Check.failed("value is not a command", f"value: {cmd}")

    @staticmethod
    def file_in_dir_pred(file: str | Path, directory: str | Path) -> bool:
        """Return True if file is strictly inside directory (after resolve)."""
        f = Path(file).resolve()
        d = Path(directory).resolve()
        if not f.exists() or not d.is_dir():
            return False
        return str(f).startswith(str(d) + os.sep)

    @staticmethod
    def file_in_dir(file: str | Path, directory: str | Path) -> None:
        """Ensure the file exists and is located inside the given directory."""
        f = Path(file).resolve()
        Check.exist(f)
        d = Path(directory).resolve()
        Check.dir(d)
        if not Check.file_in_dir_pred(f, d):
            Check.failed("file ∉ dir", f"file: {f}", f"dir: {d}")
