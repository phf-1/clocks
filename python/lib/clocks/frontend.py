# Specification

# [[id:dc574829-4e8a-46cb-94c8-09ab64d85a1a][frontend]]
#
# This module represents the frontend.
#
# root    : Directory
# version : Version  (current git short SHA)
# update  : Version  (pull + npm i, return new version)

# Implementation

from __future__ import annotations

import subprocess
from pathlib import Path

from clocks.check import Check
from clocks.fs import Fs
import shutil
import os

# Interface

class Frontend:
    @staticmethod
    def root() -> Path:
        return Fs.root() / "frontend"

    @staticmethod
    def version() -> str:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=Frontend.root(), capture_output=True, text=True,
        )
        if result.returncode != 0:
            Check.failed("Cannot read frontend version", result.stderr.strip())
        return result.stdout.strip()

    @staticmethod
    def update() -> str:
        root = Frontend.root()

        pull = subprocess.run(["git", "pull"], cwd=root, capture_output=True)
        if pull.returncode != 0:
            Check.failed("Could not update the frontend")

        npm = subprocess.run(["npm", "i"], cwd=root, capture_output=True)
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
        """Build frontend distribution pointing to the given API url (VITE_API_BASE_URL)."""
        root = Frontend.root()
        env = os.environ.copy()
        env["VITE_API_BASE_URL"] = url
        result = subprocess.run(
            ["npm", "run", "build"],
            cwd=root,
            env=env,
        )
        if result.returncode != 0:
            Check.failed("could not build the frontend distribution")
        return root / "dist"
