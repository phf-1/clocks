# Specification

# [[id:51cbff0d-4f5b-4674-83b1-8b5358434ef2][backend]]
#
# This module represents the backend.
#
# root        : Directory
# update      : ∅                  (dependencies are fetched)
# init_db     : Mode → ∅           (set up database tables)
# migrate     : Mode → ∅           (apply pending Ecto migrations)

# Implementation

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from check import Check
from fs import Fs
from db import Db
from mode import Mode
from constant import Constant
ENCODING = Constant.encoding()

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

    @staticmethod
    def init_db(mode) -> None:
        """Set up database tables (mix ecto.create)."""
        Mode.check(mode)
        root = Backend.root()
        database_url = Db.mode_url(mode)
        env = os.environ.copy()
        env["DATABASE_URL"] = database_url
        env["MIX_ENV"] = str(mode)

        result = subprocess.run(
            ["mix", "ecto.create"],
            cwd=root,
            env=env,
        )
        if result.returncode != 0:
            Check.failed("backend init_db failed", f"mode={mode}", f"stderr={result.stderr.decode(ENCODING)}")

    @staticmethod
    def migrate(mode) -> None:
        """Apply pending Ecto migrations (mix ecto.migrate)."""
        Mode.check(mode)
        root = Backend.root()
        database_url = Db.mode_url(mode)
        env = os.environ.copy()
        env["DATABASE_URL"] = database_url
        env["MIX_ENV"] = str(mode)

        result = subprocess.run(
            ["mix", "ecto.migrate"],
            cwd=root,
            env=env,
        )
        if result.returncode != 0:
            Check.failed("backend migrate failed", f"mode={mode}", f"stderr={result.stderr.decode(ENCODING)}")
