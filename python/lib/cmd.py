# [[id:e610d297-b88f-4d11-83bf-c5adfa137947][Cmd]]
#
# This module provides additional ways to run commands.

from __future__ import annotations
import subprocess
import sys
import threading

def _drain(pipe, store, sink):
    for line in pipe:
        print(line, end="", file=sink)
        sink.flush()
        store.append(line)

class Cmd:
    """
    run : List(String) → String
    """

    @staticmethod
    def run(cmd):
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
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
