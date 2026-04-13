from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

from clocks.check import Check
from clocks.fs import Fs


class Frontend:
    """
    [[id:dc574829-4e8a-46cb-94c8-09ab64d85a1a][frontend]]

    This module represents the frontend, an [[ref:9ecfad51-ad7c-461a-ac44-4ea84c8414eb][Actor]] that is in direct contact with the
    user and translates interactions into messages that are sent to the [[ref:e80d728f-2522-43ed-8d41-a509a6372828][Backend]] for
    further processing, if needed.
    """

    @staticmethod
    def root() -> Path:
        return Fs.root() / "frontend"

    @staticmethod
    def version() -> str:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            check=False,
            cwd=Frontend.root(),
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            Check.failed("Cannot read frontend version", result.stderr.strip())
        return result.stdout.strip()

    @staticmethod
    def update() -> str:
        root = Frontend.root()

        pull = subprocess.run(
            ["git", "pull"],
            check=False,
            cwd=root,
            capture_output=True,
        )
        if pull.returncode != 0:
            Check.failed("Could not update the frontend")

        npm = subprocess.run(["npm", "i"], check=False, cwd=root, capture_output=True)
        if npm.returncode != 0:
            Check.failed("Could not update frontend dependencies")

        return Frontend.version()

    @staticmethod
    def clean() -> None:
        """Delete built frontend files (equivalent to rm -rf dist/*)."""
        dist = Frontend.root() / "dist"
        if dist.exists() and dist.is_dir():
            for item in list(dist.iterdir()):
                if item.is_dir():
                    shutil.rmtree(item, ignore_errors=True)
                else:
                    item.unlink(missing_ok=True)

    @staticmethod
    def dist(url: str) -> Path:
        """String → Path

        Given a string that represents the URL where the [[ref:e80d728f-2522-43ed-8d41-a509a6372828][Backend]] listens for
        messages, return a path to a directory of a [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]]. When
        executed by the client, the makes request to the backend through the provided
        URL.
        """

        root = Frontend.root()
        env = os.environ.copy()
        env["VITE_API_BASE_URL"] = url
        result = subprocess.run(
            ["npm", "run", "build"],
            check=False,
            cwd=root,
            env=env,
        )
        if result.returncode != 0:
            Check.failed("could not build the frontend distribution")
        return root / "dist"
