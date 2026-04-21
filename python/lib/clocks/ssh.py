from __future__ import annotations
import subprocess
import time
from functools import cache

from clocks.authority import Authority
from clocks.fs import Fs
from clocks.string import String
from clocks.check import Check
from clocks.guix import Guix
from clocks.maybe import Maybe
from clocks.nat import Nat

_host_key_cache: dict[Authority, Maybe] = {}
def _host_key(authority: Authority) -> Maybe:
    """Authority → Maybe(HostKey)"""
    Authority.check(authority)
    if authority in _host_key_cache:
        return _host_key_cache[authority]
    ip = Authority.ip(authority)
    port = Authority.port(authority)
    try:
        result = subprocess.run(
            ["ssh-keyscan", "-T", "1", "-t", "ed25519", "-p", str(port), str(ip)],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except Exception:
        return Maybe.nothing()
    if result.returncode == 0:
        host_key = result.stdout.strip().split()[-1]
        success = Maybe.just(host_key)
        _host_key_cache[authority] = success
        return success
    return Maybe.nothing()

_ssh_config = """# begin([[ref:3946d10f-4ba6-4848-97d8-ed3d00893cf3][Ssh]])
Host 127.0.0.1 localhost
    User root
    IdentityFile {project_root}/ssh/ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR

# GitHub (accept new keys once)
Host github.com
    StrictHostKeyChecking accept-new
# end
"""

class Ssh:
    """
    [[id:3946d10f-4ba6-4848-97d8-ed3d00893cf3][Ssh]]

    This module represents an SSH client.

    HostKey ≡ String
    """

    def __init__(self):
        if Guix.container_is_active():
            self._root = root = Fs.ssh()
            root.mkdir(parents=True, exist_ok=True)
            root.chmod(0o700)
            config = root / "config"
            ssh_config_content = _ssh_config.format(project_root=Fs.root())
            if not config.exists() or ssh_config_content.strip() not in config.read_text(encoding="utf-8"):
                with config.open("a", encoding="utf-8") as f:
                    f.write("\n" + ssh_config_content)
            config.chmod(0o600)
            for pattern in ["id_*", "*.pub", "known_hosts"]:
                for f in root.glob(pattern):
                    if f.is_file():
                        f.chmod(0o600 if "id_" in f.name else 0o644)

    @staticmethod
    def mk() -> Ssh:
        return Ssh()

    @staticmethod
    def is_a(value: any) -> bool:
        return isinstance(value, Ssh)

    @staticmethod
    def check(value: any) -> None:
        if not Ssh.is_a(value):
            Check.failed("ssh is not a Ssh", f"ssh={value}")

    @staticmethod
    def host_key(authority: Authority) -> Maybe:
        """Authority → Maybe(HostKey)"""
        Authority.check(authority)
        return _host_key(authority)

    @staticmethod
    def is_running(authority: Authority, seconds: Nat) -> bool:
        """Authority Nat → bool"""
        Authority.check(authority)
        Nat.check(seconds)
        timeout = Nat.int(seconds)
        start = time.time()
        while (time.time() - start) < timeout:
            time.sleep(0.5)
            maybe_key = _host_key(authority)
            if not Maybe.is_nothing(maybe_key):
                return True
        return False

    @staticmethod
    def is_running_check(authority: Authority, seconds: Nat) -> None:
        """Authority Nat → None"""
        Authority.check(authority)
        Nat.check(seconds)
        if not Ssh.is_running(authority, seconds):
            Check.failed(
                "Ssh daemon is not responsive",
                f"authority: {authority}",
                f"timeout={Nat.int(seconds)} sec"
            )

    @staticmethod
    def connect(ssh: Ssh, user: str, authority: Authority):
        Ssh.check(ssh)
        String.check(user)
        Authority.check(authority)
        ip = Authority.ip(authority)
        port = Authority.port(authority)
        cmd = ["ssh", f"{user}@{ip}", "-p", str(port)]
        subprocess.run(cmd, check=True)
