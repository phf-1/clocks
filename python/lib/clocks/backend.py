# [[id:51cbff0d-4f5b-4674-83b1-8b5358434ef2][backend]]
#
# This module represents the backend.

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from clocks.check import Check
from clocks.constant import Constant
from clocks.db import Db
from clocks.fs import Fs
from clocks.mode import Mode
from clocks.port import Port

_ENCODING = Constant.encoding()
_DEV_PORT = Port.mk(4002)
_TEST_PORT = Port.mk(4001)
_PROD_PORT = Port.mk(8443)


class Backend:
    """
    [[id:e80d728f-2522-43ed-8d41-a509a6372828][Backend]]

    The backend is the program that implements an [[ref:9ecfad51-ad7c-461a-ac44-4ea84c8414eb][Actor]] that receives messages from
    the [[ref:dc574829-4e8a-46cb-94c8-09ab64d85a1a][frontend]] and should reply accordingly.
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
            result = subprocess.run(cmd, check=False, cwd=root)
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
            check=False,
            cwd=root,
            env=env,
        )
        if result.returncode != 0:
            Check.failed(
                "backend init_db failed",
                f"mode={mode}",
                f"stderr={result.stderr.decode(_ENCODING)}",
            )

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
            check=False,
            cwd=root,
            env=env,
        )
        if result.returncode != 0:
            Check.failed(
                "backend migrate failed",
                f"mode={mode}",
                f"stderr={result.stderr.decode(_ENCODING)}",
            )

    @staticmethod
    def url(mode: Mode) -> str:
        """Mode → String

        Given a mode, return the URL where the backend listens for messages.

        For instance: http://localhost:4000/api
        """

        Mode.check(mode)
        if mode == Mode.prod():
            # TODO(d1b8): should be a parameter.
            return f"https://todo.test.phfrohring.com/api"
        else:
            # TODO(15aa): prod => https, dev => http, else CORS issues
            port = Backend.port(mode)
            return f"https://localhost:{port}/api"

    @staticmethod
    def install_frontend(frontend_dist: Path) -> None:
        Check.dir(frontend_dist)
        root = Backend.root()
        target = root / "priv" / "static"
        target.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            ["rsync", "-a", "--delete", f"{frontend_dist}/", str(target)],
            check=False,
        )
        if result.returncode != 0:
            Check.failed("Cannot install frontend dist in the backend")
        return Backend

    @staticmethod
    def dist(frontend_dist: Path) -> Path:
        """Path → Path

        Given a path to a directory that contains a [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]], then
        return a directory that contains a [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][BackendDistribution]]. The frontend will be
        served by the backend.
        """

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
            result = subprocess.run(cmd, check=False, cwd=root, env=env)
            if result.returncode != 0:
                Check.failed("backend dist failed", f"cmd={' '.join(cmd)}")
        return release_path.parent

    @staticmethod
    def repl() -> None:
        root = Backend.root()
        subprocess.run(
            ["iex", "--dbg", "pry", "-S", "mix", "phx.server"],
            check=False,
            cwd=root,
        )

    @staticmethod
    def test() -> None:
        """Execute all Elixir/Phoenix tests (mix test)."""
        root = Backend.root()
        result = subprocess.run(["mix", "test"], check=False, cwd=root)
        if result.returncode != 0:
            Check.failed("Backend tests failed")
