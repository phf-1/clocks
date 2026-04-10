# Specification

# [[id:0ce4f75d-9887-4ab5-9b50-fe603ce25555][scheme]]
#
# This module represents scheme code
#
# root    : Directory

# Implementation

from __future__ import annotations

from pathlib import Path

from clocks.fs import Fs

# Interface


class Scheme:
    @staticmethod
    def root() -> Path:
        return Fs.root() / "scheme"
