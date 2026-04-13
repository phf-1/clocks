from __future__ import annotations

import shutil
from pathlib import Path

from clocks.check import Check
from clocks.cmd import Cmd
from clocks.fs import Fs
from clocks.osys import Osys
from clocks.module import Module
from clocks.guix import Guix
from dataclasses import dataclass
import tempfile

_IMAGE_DIR = Fs.root() / "image"
_IMAGE_DIR.mkdir(parents=True, exist_ok=True)


def _name_to_path(name):
    return _IMAGE_DIR / f"{name}.qcow2"


@dataclass
class Image:
    """
    [[id:0c323aa3-4e48-4d72-83cf-9481324cf274][Image]]

    An Image represents a [[ref:2b855eac-c24c-4d19-a966-e8bf89be994c][DiskImage]].
    """

    _osys: Osys
    _qcow2: None | Path
    _guix: Guix

    @staticmethod
    def mk(osys):
        from clocks.guix import Guix

        qcow2 = _name_to_path(Osys.name(osys))

        # TODO(1669): no
        if not qcow2.is_file():
            qcow2 = None

        return Image(osys, qcow2, Guix())

    @staticmethod
    def elim(func):
        """(Osys Path → C) → Image → C"""

        def closure(value):
            match value:
                case Image(_osys=os, _qcow2=qcow2):
                    return func(os, qcow2)
                case _:
                    Check.failed("value is not a Image.", f"value: {value}")

        return closure

    @staticmethod
    def is_a(x):
        return isinstance(x, Image)

    @staticmethod
    def check(value) -> None:
        if not Image.is_a(value):
            Check.failed("value is not an Image", f"value={value}")

    @staticmethod
    def qcow2(image: Image) -> Path:
        """Image → Path

        Given an image, then return its associated QCOW2 file path
        """

        def _proc(os, qcow2):
            # TODO(89f3): compare the hash
            if qcow2 is not None:
                return qcow2
            else:
                os._qcow2 = _name_to_path(Osys.name(os))
                module = Osys.module(os)
                try:
                    tmp_d = Path(tempfile.mkdtemp(suffix="-guix"))
                    file = Module.install(module, tmp_d)
                    cmd = [
                        "guix",
                        "time-machine",
                        "-C",
                        str(Fs.channels()),
                        "--",
                        "system",
                        "image",
                        "-t",
                        "qcow2",
                        "--image-size=20G",
                        str(file),
                    ]

                    if not Guix.container_is_active(image._guix):
                        Check.failed("An image cannot be built outside of a container")
                    result = Cmd.run(cmd)
                    built = Path(result.strip())
                    shutil.copy2(built, os._qcow2)
                    os._qcow2.touch()
                    return os._qcow2
                finally:
                    if tmp_d:
                        shutil.rmtree(tmp_d)

        return Image.elim(_proc)(image)

    @staticmethod
    def osys(image):
        def _proc(os, qcow2):
            return os

        return Image.elim(_proc)(image)

    @staticmethod
    def name(image):
        def _proc(os, qcow2):
            return Osys.name(os)

        return Image.elim(_proc)(image)
