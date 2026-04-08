# [[id:3946d10f-4ba6-4848-97d8-ed3d00893cf3][Ssh]]
#
# This module represents Ssh.

from __future__ import annotations
import subprocess
from fs import Fs
from ip import Ip
from port import Port
from check import Check
from guix import Guix

class Ssh:
    """
    connect : User Ip Port → ∅
    """

    def __init__(self):
        if Guix.container_is_active():
            self._root = root = Fs.ssh()
            root.mkdir(parents=True, exist_ok=True)
            root.chmod(0o700)
            config = root / "config"
            vm_section = """# Added by: [[ref:3946d10f-4ba6-4848-97d8-ed3d00893cf3][Ssh]]
Host 127.0.0.1 localhost
    User root
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR

# GitHub (accept new keys once)
Host github.com
    StrictHostKeyChecking accept-new
"""

            if not config.exists() or vm_section.strip() not in config.read_text(encoding="utf-8"):
                with config.open("a", encoding="utf-8") as f:
                    f.write("\n" + vm_section)

            config.chmod(0o600)

            for pattern in ["id_*", "*.pub", "known_hosts"]:
                for f in root.glob(pattern):
                    if f.is_file():
                        f.chmod(0o600 if "id_" in f.name else 0o644)

    @staticmethod
    def mk():
        return Ssh()

    @staticmethod
    def is_a(value):
        return isinstance(value, Ssh)

    @staticmethod
    def check(value: str) -> None:
        if not Ssh.is_a(value):
            Check.failed("ssh is not a Ssh", f"ssh={value}")

    @staticmethod
    def connect(ssh, user, ip, port):
        Ssh.check(ssh)
        Ip.check(ip)
        Port.check(port)
        cmd = ["ssh", f"{user}@{ip}", "-p", f"{port}"]
        subprocess.run(cmd, check=True)
