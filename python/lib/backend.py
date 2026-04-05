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
from port import Port

_ENCODING = Constant.encoding()
_DEV_PORT  = Port(4000)
_TEST_PORT = Port(4001)
_PROD_PORT = Port(4002)

# Interface

class Backend:
    @staticmethod
    def root() -> Path:
        p = Fs.root() / "backend"
        Check.dir(p)
        return p

    @staticmethod
    def dev_port():
        return _DEV_PORT

    @staticmethod
    def test_port():
        return _TEST_PORT

    @staticmethod
    def prod_port():
        return _PROD_PORT
    
    @staticmethod
    def mode_port(mode) -> int:
        return Mode.elim(Backend.dev_port, Backend.test_port, Backend.prod_port)(mode)

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
            Check.failed("backend init_db failed", f"mode={mode}", f"stderr={result.stderr.decode(_ENCODING)}")

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
            Check.failed("backend migrate failed", f"mode={mode}", f"stderr={result.stderr.decode(_ENCODING)}")

    @staticmethod
    def mode_url(mode) -> str:
        """http://localhost:port/api (used by frontend build)."""
        Mode.check(mode)
        port = Backend.mode_port(mode)
        return f"http://localhost:{port}/api"            

    @staticmethod
    def install_frontend(frontend_dist: Path) -> None:
        """Rsync frontend distribution into backend/priv/static (matches Bash)."""
        Check.dir(frontend_dist)
        root = Backend.root()
        target = root / "priv" / "static"
        target.mkdir(parents=True, exist_ok=True)

        result = subprocess.run(
            ["rsync", "-a", "--delete", f"{frontend_dist}/", str(target)],
        )
        if result.returncode != 0:
            Check.failed("Cannot install frontend dist in the backend")

    @staticmethod
    def dist(frontend_dist: Path) -> Path:
        """Build a Phoenix release distribution (MIX_ENV=prod)."""
        Check.dir(frontend_dist)
        Backend.install_frontend(frontend_dist)

        root = Backend.root()
        mix_env = "prod"
        release_path = root / "_build" / mix_env / "rel" / "dist"

        env = os.environ.copy()
        env["MIX_ENV"] = mix_env

        cmds = [
            ["mix", "deps.get", "--only", mix_env],
            ["mix", "compile"],
            ["mix", "assets.deploy"],
            ["mix", "phx.gen.release"],
            ["mix", "release", "--overwrite", "--path", str(release_path)],
        ]

        for cmd in cmds:
            result = subprocess.run(cmd, cwd=root, env=env)
            if result.returncode != 0:
                Check.failed("backend dist failed", f"cmd={' '.join(cmd)}")

        return release_path
