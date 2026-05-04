from __future__ import annotations

import subprocess
from pathlib import Path

from clocks.check import Check


class Fs:
    """
    [[id:b394674a-148b-4f10-9c5e-1166e8b86793][fs]]

    This module represents the filesystem.
    """

    @staticmethod
    def root() -> Path:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            Check.failed("Cannot determine repository root", result.stderr.strip())
        return Path(result.stdout.strip())

    @staticmethod
    def scheme() -> Path:
        return Fs.root() / "scheme"

    @staticmethod
    def python() -> Path:
        return Fs.root() / "python"

    @staticmethod
    def python_data() -> Path:
        return Fs.python() / "data"

    @staticmethod
    def ssh() -> Path:
        return Path.home() / ".ssh"

    @staticmethod
    def channels() -> Path:
        return Fs.scheme() / "clocks" / "channels.scm"
