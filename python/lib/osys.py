# Specification

# [[id:b10f3eef-3767-4d1b-b690-71f36f619fd9][OS]]
#
# os : OS represents an [[ref:be4a5e39-7ec4-43ed-9d96-376db49ce782][OS]]
#
# To build an OS, add a definition to the appropriate directory
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))
# init : OS
# spec : OS → Path
# list : List(OS)
# ssh_port : OS → Port
# user : OS → User
# package_d : OS → Directory
# scheme : OS → Scheme
# machine : OS → [[ref:6ab03cba-6319-43bf-acc2-d74e77e95198][Machine]]
# name : OS → String

# Implementation

from __future__ import annotations
import subprocess

from check import Check
from fs import Fs

_SCHEME_VM = Fs.root() / "scheme" / "app" / "vm"
Check.dir(_SCHEME_VM)

def _value(spec, var: str) -> str:
    # Extract (define %var value) from Scheme file (exact Bash rg logic)
    result = subprocess.run(
        ["rg", "-m", "1", "-o", "-I", "-r", "$1", rf"\(define %{var} +([^)]+)\)", str(spec)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 or not result.stdout.strip():
        Check.failed("Cannot read var from os", f"var={var}", f"spec={spec}")
    value = result.stdout.strip()
    # Strip surrounding quotes if present
    if value.startswith('"') and value.endswith('"'):
        value = value[1:-1]
    return value

# Interface

class Osys:
    def __init__(self, name):
        self._name = name        
        self._spec = spec = _SCHEME_VM / name / "os.scm"
        spec.is_file() or Check.failed("name does not match an os.scm", f"name: {name}")
        
    @staticmethod
    def is_a(x):
        return isinstance(x, Osys)
    
    @staticmethod
    def check(value) -> None:
        if not Osys.is_a(value):
            Check.failed("value is not an OS", f"value={value}")

    @staticmethod
    def elim(func):
        def closure(osys):
            Osys.check(osys)
            return func(osys._name, osys._spec)
        return closure

    @staticmethod
    def name(osys):
        return Osys.elim(lambda name, spec: name)(osys)

    @staticmethod
    def spec(osys):
        return Osys.elim(lambda name, spec: spec)(osys)
    
    @staticmethod
    def ssh_port(osys):
        return Osys.elim(lambda name, spec: _value(spec, "ssh-port"))(osys)

    @staticmethod
    def root_key(osys):
        return Osys.elim(lambda name, spec: _value(spec, "root-pub-key"))(osys)

    @staticmethod
    def store_key(osys):
        return Osys.elim(lambda name, spec: _value(spec, "store-pub-key"))(osys)
    
    def __str__(self):
        return f"Osys(name: {self._name})"
