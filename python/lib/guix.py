# [[id:184e8f75-3a8f-40d1-9c1c-fe30dd50e083][Guix]]
#
# This module represents Guix.

from __future__ import annotations
import subprocess
import os

# ["a", "b"] ↦ '(a b)'
def _module(names):
    joined = ' '.join(names)
    return f'({joined})'

# 1 ↦ '1'
# "a" → '"a"'
def _serialize_value(value):
    if isinstance(value, str):
        return f'"{value}"'
    return str(value)

# "name" ["a" 1] ↦ '(name "a" 1)'
def _func_call(name, params):
    serialized = ' '.join(map(_serialize_value, params))
    return f'({name} {serialized})'

# ["vm", "machine"] ["a" 1] ↦ f'(begin (use-modules (vm machine)) (list (machine "a" 1)))'
def _expression(names, params):
    module = _module(names)
    func_call = _func_call(names[-1], params)
    return f'(begin (use-modules {module}) (list {func_call}))'

def _guix_deploy(names, params):
    env = os.environ.copy()
    expression = _expression(names, params)
    return subprocess.run(
        ["guix", "deploy", "-e", expression],
        env=env,
        check=True
    )

class Guix:
    """
    Module :≡ List(String)
    Params :≡ List(String)
    deploy : Module Params → subprocess.CompletedProcess
    """

    @staticmethod
    def deploy(names, params):
        return _guix_deploy(names, params)
