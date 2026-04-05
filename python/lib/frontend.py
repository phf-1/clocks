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

from check import Check
from fs import Fs

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
