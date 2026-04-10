from __future__ import annotations

import shutil
import subprocess
import sys
import threading
from pathlib import Path

from clocks.maybe import Maybe


def _drain(pipe, store, sink):
    for line in pipe:
        print(line, end="", file=sink)
        sink.flush()
        store.append(line)


class Cmd:
    """[[id:e610d297-b88f-4d11-83bf-c5adfa137947][Cmd]]

    This module provides additional ways to run commands.
    """

    @staticmethod
    def run(cmd: list, cwd: None | Path = None) -> str:
        """List(String) → String"""
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            cwd=cwd,
        )
        out, err = [], []
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
    def exists(cmd: list) -> bool:
        """List(String) → Boolean"""
        return shutil.which(cmd[0]) is not None

    @staticmethod
    def run_if_exists(cmd: list, cwd: None | Path = None) -> Maybe:
        """List(String) → Maybe(String)"""
        if Cmd.exists(cmd):
            return Maybe.just(Cmd.run(cmd, cwd=cwd))
        return Maybe.nothing()
