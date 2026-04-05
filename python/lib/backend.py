# Specification

# [[id:51cbff0d-4f5b-4674-83b1-8b5358434ef2][backend]]
#
# This module represents the backend.
#
# root   : Directory
# update : ∅  (dependencies are fetched)

# Implementation

from __future__ import annotations

import subprocess
from pathlib import Path

from fs import Fs
from check import Check

# Interface

class Backend:
    @staticmethod
    def root() -> Path:
        p = Fs.root() / "backend"
        Check.dir(p)
        return p
    
    @staticmethod    
    def update() -> None:
        root = Backend.root()
        for cmd in (
            ["mix", "local.hex", "--force", "--if-missing"],
            ["mix", "deps.get"],
        ):
            result = subprocess.run(cmd, cwd=root)
            if result.returncode != 0:
                Check.failed("update failed", f"cmd={' '.join(cmd)}")
