# [[id:51cbff0d-4f5b-4674-83b1-8b5358434ef2][backend]]
#
# This module represents the backend.

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
_DEV_PORT  = Port.mk(4000)
_TEST_PORT = Port.mk(4001)
_PROD_PORT = Port.mk(4002)

class Backend:
    """
    root : Directory         :≡ Where the backend code is stored
    update : Backend         :≡ Fetch dependencies.
    init_db : Mode → Backend :≡ Set up database tables
    migrate : Mode → Backend :≡ Apply pending Ecto migrations
    port : Mode → Port       :≡ Port when backend operates in mode
    install_frontend : [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]] → Backend :≡ Install the frontend in the backend
    dist : [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]] → [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][PhoenixDistribution]] :≡ Path to a backend distribution
    repl : TODO
    test : TODO
    """

    @staticmethod
    def root() -> Path:
        p = Fs.root() / "backend"
        Check.dir(p)
        return p

    @staticmethod
    def port(mode) -> int:
        return Mode.elim(_DEV_PORT, _TEST_PORT, _PROD_PORT)(mode)

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
        database_url = Db.url(mode)
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
        database_url = Db.url(mode)
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
    def url(mode) -> str:
        Mode.check(mode)
        port = Backend.port(mode)
        return f"http://localhost:{port}/api"

    @staticmethod
    def install_frontend(frontend_dist: Path) -> None:
        Check.dir(frontend_dist)
        root = Backend.root()
        target = root / "priv" / "static"
        target.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            ["rsync", "-a", "--delete", f"{frontend_dist}/", str(target)],
        )
        if result.returncode != 0:
            Check.failed("Cannot install frontend dist in the backend")
        return Backend

    @staticmethod
    def dist(frontend_dist: Path) -> Path:
        Check.dir(frontend_dist)
        Backend.install_frontend(frontend_dist)
        root = Backend.root()
        mix_env = Mode.string(Mode.prod())
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

    @staticmethod
    def repl() -> None:
        root = Backend.root()
        subprocess.run(
            ["iex", "--dbg", "pry", "-S", "mix", "phx.server"],
            cwd=root,
        )

    @staticmethod
    def test() -> None:
        """Execute all Elixir/Phoenix tests (mix test)."""
        root = Backend.root()
        result = subprocess.run(["mix", "test"], cwd=root)
        if result.returncode != 0:
            Check.failed("Backend tests failed")
