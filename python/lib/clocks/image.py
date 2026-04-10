# [[id:0c323aa3-4e48-4d72-83cf-9481324cf274][Image]]
#
# An Image represents a [[ref:2b855eac-c24c-4d19-a966-e8bf89be994c][DiskImage]].

from __future__ import annotations

import shutil
from pathlib import Path

from clocks.check import Check
from clocks.cmd import Cmd
from clocks.fs import Fs
from clocks.osys import Osys

_IMAGE_DIR = Fs.root() / "image"
_IMAGE_DIR.mkdir(parents=True, exist_ok=True)


def _name_to_path(name):
    return _IMAGE_DIR / f"{name}.qcow2"


class Image:
    """mk : [[ref:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]] → Image
    elim : (Osys Path → C) → Image → C
    os : Image → OS
    qcow2 : Image → Path
    name : Image → String
    """

    def __init__(self, osys, inside_container=False):
        Osys.check(osys)
        self._osys = osys
        self._qcow2 = qcow2 = _name_to_path(Osys.name(osys))
        spec = Osys.spec(osys)
        if (not qcow2.exists()) or (qcow2.stat().st_mtime <= spec.stat().st_mtime):
            if inside_container:
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
                    str(spec),
                ]
                result = Cmd.run(cmd)
                built = Path(result.strip())
                if qcow2.exists():
                    qcow2.unlink(missing_ok=True)
                shutil.copy2(built, qcow2)
                qcow2.touch()
            else:
                Check.failed("An image cannot be built outside of a container")

    # TODO(3d6d): False should not be a default
    @staticmethod
    def mk(osys, inside_container=False):
        return Image(osys, inside_container)

    @staticmethod
    def is_a(x):
        return isinstance(x, Image)

    @staticmethod
    def check(value) -> None:
        if not Image.is_a(value):
            Check.failed("value is not an Image", f"value={value}")

    @staticmethod
    def elim(func):
        def closure(image):
            Image.check(image)
            return func(image._osys, image._qcow2)

        return closure

    @staticmethod
    def qcow2(image):
        return Image.elim(lambda _osys, qcow2: qcow2)(image)

    @staticmethod
    def osys(image):
        return Image.elim(lambda osys, _qcow2: osys)(image)

    @staticmethod
    def name(image):
        return Image.elim(lambda osys, _qcow2: Osys.name(osys))(image)
