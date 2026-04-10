from __future__ import annotations

import shutil
import subprocess
import sys
import threading
from typing import IO, TYPE_CHECKING, TextIO

if TYPE_CHECKING:
    from pathlib import Path

from clocks.log import Log
from clocks.maybe import Maybe


def _drain(pipe: IO[str], store: list[str], sink: TextIO) -> None:
    """IO(String) List(String) TextIO → None"""
    for line in pipe:
        print(line, end="", file=sink)
        sink.flush()
        store.append(line)


class Cmd:
    """[[id:e610d297-b88f-4d11-83bf-c5adfa137947][Cmd]]

    This module provides additional ways to run commands.
    """

    @staticmethod
    def run(cmd: list[str], cwd: Path | None = None) -> str:
        """List(String) → String"""
        proc = subprocess.Popen(  # noqa: S603
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            cwd=cwd,
        )
        out: list[str] = []
        err: list[str] = []
        t1 = threading.Thread(target=_drain, args=(proc.stdout, out, sys.stdout))
        t2 = threading.Thread(target=_drain, args=(proc.stderr, err, sys.stderr))
        t1.start()
        t2.start()
        t1.join()
        t2.join()
        proc.wait()
        if proc.returncode != 0:
            raise subprocess.CalledProcessError(proc.returncode, proc.args)
        return "".join(out)

    @staticmethod
    def exists(cmd: list[str]) -> bool:
        """List(String) → Boolean"""
        return shutil.which(cmd[0]) is not None

    @staticmethod
    def run_if_exists(cmd: list[str], cwd: Path | None = None) -> Maybe:
        """List(String) → Maybe(String)"""
        if Cmd.exists(cmd):
            return Maybe.just(Cmd.run(cmd, cwd=cwd))
        cmd_string = " ".join(cmd)
        Log.info("command not found", f"cmd: {cmd_string}")
        return Maybe.nothing()
