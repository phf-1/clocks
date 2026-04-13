from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path

from clocks.app import App
from clocks.authority import Authority
from clocks.backend import Backend
from clocks.check import Check
from clocks.cmd import Cmd
from clocks.constant import Constant
from clocks.db import Db
from clocks.frontend import Frontend
from clocks.fs import Fs
from clocks.guix import Guix
from clocks.help import Help
from clocks.image import Image
from clocks.ip import Ip
from clocks.log import Log
from clocks.maybe import Maybe
from clocks.string import String
from clocks.mode import Mode
from clocks.osys import Osys
from clocks.params import Params
from clocks.message import Message
from clocks.ssh import Ssh
from clocks.package import Package
from clocks.vm import Vm

failed = Check.failed
ok = Log.ok
info = Log.info
debug = Log.debug
error = Log.error
ssh = Ssh.mk()

ENCODING = Constant.encoding()
CMD_RE = re.compile(r" *# (,.+)$")

SPEC = """
What is the objective of this script?

  Its objective is to minimize the cost of executing repetitive tasks. This script
  makes this directory respond to commands, automating various tasks, like starting
  the REPL, executing tests or formatting code.

How to use this script?

  if: $ ln -s this_script a_command,
  then: $ a_command param is identical to invoking the script with <a_command, [param]>

How to choose a new command name?

  command_name :≡ "," (component "-")? verb ("-" param)*
  example :≡ ,help
  example :≡ ,backend-test

  Commands start with a comma "," so that they are easy to differentiate from
  non-project commands. For instance: ",help".

  If the command is addressed to the project itself, then it starts with a verb. For
  instance: ",help".

  If the command is addressed to a part of the project, then it starts with the name
  of that part and then a verb. For instance: ",backend-test".

  To add a new command, just look at the implementation, copy/paste the simplest one,
  start from there.

How to add a new command?

  To add a new command, just look at the implementation, copy/paste the simplest one,
  start from there.

How is this script structured?

  Assume that cmd is the name of this script, then invoking this script must be
  understood as follows:

  $ ./cmd param1 param2 :≡
    message :≡ <cmd, [param1 param2]>

    case message
      <a, []> ↦
        # do something

      <cmd, [x,y]> ↦
        # do something

      … ↦
        # do something

      _ ↦
        error "unexpected message"
"""


def _help(self):
    print(Help.string(Path(os.path.realpath(__file__))))


def _update_deps():
    Backend.update()
    version = Frontend.update()
    ok(
        "Dependencies not directly managed by Guix have been updated",
        f"frontend version: {version}",
    )


def _install_commands(self):
    bin_dir = self._bin
    os.chdir(bin_dir)
    for link in bin_dir.glob(",*"):
        link.unlink()
    ok("Old command symlinks have been removed")
    for line in (
        Path(os.path.realpath(__file__)).read_text(encoding=ENCODING).splitlines()
    ):
        if m := CMD_RE.match(line):
            cmd = m.group(1).split(" ")[0]
            symlink = bin_dir / f"{cmd}"
            symlink.symlink_to(self._name)
            ok(f"{cmd}")
    ok("All command symlinks are up to date")


class Projectctl:
    """
    [[id:344d2579-2d67-4901-8e70-1849eea0c843][Projectctl]]

    This class automatizes operations like starting the database, linting source
    files, or deploying the application. It is what gives meaning to messages sent to
    the CLI. It is also self-documenting, see: _help.
    """

    # TODO(4401): remove _path
    def __init__(self, _path, root, bin, name):
        self._root = root
        self._bin = bin
        self._name = name

    @staticmethod
    def mk(_path, root, bin, name):
        # Project root
        Check.dir(root)
        # Project binaries
        Check.dir(bin)
        # Name of the CLI, e.g. "projectctl"
        String.check(name)
        return Projectctl(_path, root, bin, name)

    @staticmethod
    def rcv(self, msg: Message):
        Message.check(msg)
        prop = Message.prop(msg)
        params = Message.params(msg)[0]
        guix = Guix()

        # INSTALLATION #

        # ,install-commands
        #   (Re)install commands
        if prop == ",install-commands":
            _install_commands(self)

        # ,update-deps
        #   Update dependencies not directly managed by Guix
        elif prop == ",update-deps":
            _update_deps()

        # Executing this script directly installs commands and fetches dependencies
        elif prop == self._name:
            install_link = Path(self._bin) / ",install-commands"
            install_link.unlink(missing_ok=True)
            install_link.symlink_to(self._name)
            _update_deps()
            _install_commands(self)

        # DEVELOPMENT #

        # ,help
        #   Print commands and descriptions
        elif prop == ",help":
            _help(self)

        # ,list-todo
        #   List todos
        elif prop == ",list-todo":
            result = subprocess.run(["rg", "-F", "TODO", str(Fs.root())], check=False)
            if result.returncode not in (0, 1):
                Check.failed("rg failed", f"returncode={result.returncode}")
            ok("List TODOs")

        # DATABASE #

        # ,db-init (Mode :≡ dev|test|prod)
        #   Creates a directory for the DB data.
        elif prop == ",db-init":
            mode = Params.mode_check(params, 0)
            db_data = Db.init(mode)
            ok(
                "The PostgreSQL cluster has been initialized",
                f"mode={mode}",
                f"db_data={db_data}",
            )

        # ,db-start Mode
        #   Start a PostgreSQL process
        elif prop == ",db-start":
            mode = Params.mode_check(params, 0)
            Db.start(mode)
            ok("The PostgreSQL instance is started")

        # ,db-status Mode
        #   Status a PostgreSQL process
        elif prop == ",db-status":
            mode = Params.mode_check(params, 0)
            match Db.status(mode):
                case ["running", status]:
                    ok(status)
                case _:
                    ok(f"Database in mode {mode} is not running")

        # ,db-clean
        #   Remove PostgreSQL directories
        elif prop == ",db-clean":
            Db.clean()
            ok("DB cleaned", f"DBROOT={Db.root()}")

        # FRONTEND #

        # ,frontend-update
        #   Update the frontend to the last version
        elif prop == ",frontend-update":
            version = Frontend.update()
            ok("The frontend has been updated", f"version={version}")

        # ,frontend-dist Mode
        #   Build a frontend distribution
        elif prop == ",frontend-dist":
            mode = Params.mode_check(params, 0)
            url = Backend.url(mode)
            dist = Frontend.dist(url)
            ok(
                "A frontend distribution in mode has been built",
                f"dist: {dist}",
                f"mode: {mode}",
            )

        # ,frontend-clean
        #   Delete built files
        elif prop == ",frontend-clean":
            Frontend.clean()
            ok("Frontend generated files are deleted")

        # BACKEND #

        # ,backend-update
        #   Update the backend dependencies
        elif prop == ",backend-update":
            Backend.update()
            ok("The backend dependencies have been updated")

        # ,backend-init-db Mode
        #   Set up database tables
        elif prop == ",backend-init-db":
            mode = Params.mode_check(params, 0)
            Backend.init_db(mode)
            ok("The database tables have been created", f"mode={mode}")

        # ,backend-migrate Mode
        #   Apply pending Ecto migrations to the database
        elif prop == ",backend-migrate":
            mode = Params.mode_check(params, 0)
            Backend.migrate(mode)
            ok("Ecto migration has been applied to the database", f"mode={mode}")

        # ,backend-test
        #   Execute all Elixir tests
        elif prop == ",backend-test":
            Backend.test()
            ok("Backend tests executed")

        # ,backend-dist
        #   Build a backend distribution
        elif prop == ",backend-dist":
            url = Backend.url(Mode.prod())
            info("Build the frontend distribution at url", f"url={url}")
            frontend_dist = Frontend.dist(url)
            ok("dist=", str(frontend_dist))
            info("Build the backend distribution")
            dist = Backend.dist(frontend_dist)
            ok("A backend distribution has been built", f"dist={dist}")

        # ,backend-clean
        #   Remove the Phoenix build artifacts and dependencies
        elif prop == ",backend-clean":
            Backend.clean()
            ok("Backend directory cleaned", f"PHX={Backend.root()}")

        # IMAGE #

        # ,image-build OS
        #   Build an image for OS within the container (OS :≡ init | dev)
        elif prop == ",image-build":
            name = Params.string_check(params, 0)
            # TODO(347b): name → …
            osys = Osys.init()
            image = Image.mk(osys)
            ok(f"image: {Image.qcow2(image)}")

        # VM #

        # ,vm-start OS Ip SshPort HttpPort HttpsPort
        #   Start a local VM built from OS and listening on SshPort, HttpPort, and HttpsPort
        elif prop == ",vm-start":
            name = Params.string_check(params, 0)
            ip = Params.ip_check(params, 1)
            ssh_port = Params.port_check(params, 2)
            http_port = Params.port_check(params, 3)
            https_port = Params.port_check(params, 4)
            if name == "init":
                osys = Osys.init()
                image = Image.mk(osys)
                vm = Vm.mk(image, ip, ssh_port, http_port, https_port)
                Vm.start(vm)
                port = Vm.ssh_port(vm)
                ok(
                    "A new local VM to test deployment (as if it was a VPS) has been built",
                )
                ok(
                    f"Connect to the VM from the container with: ,ssh-connect-dev-vm {port}",
                )
            else:
                Check.failed("Unexpected name", f"name: {name}")

        # DEPLOYMENT #

        # ,deploy OS Authority
        #   Deploy OS to Authority (Authority :≡ Ip:Port)
        elif prop == ",deploy":
            # [[id:d54cd93f-2105-415a-a643-aa7edb60ad35]]
            name = Params.string_check(params, 0)
            authority = Params.authority_check(params, 1)
            if name == "init":
                os = Osys.init()
                Guix.deploy(guix, os, authority)
            elif name == "dev":
                mode = Mode.prod()
                url = Backend.url(mode)
                frontend_dist = Frontend.dist(url)
                dist = Backend.dist(frontend_dist)
                pkg = Package.mk(dist)
                os = Osys.dev(pkg)
                Guix.deploy(guix, os, authority)
            else:
                Check.failed("name is not a deployment name", f"name: {name}")

        # APP #

        # ,app-repl
        #   Start the application and drop into iex
        elif prop == ",app-repl":
            mode = Mode.dev()
            Db.init(mode)
            Db.start(mode)
            Backend.init_db(mode)
            Backend.migrate(mode)
            url = Backend.url(mode)
            frontend_dist = Frontend.dist(url)
            Backend.install_frontend(frontend_dist)
            Backend.repl()

        # ,app-test
        #   Execute tests
        elif prop == ",app-test":
            Backend.test()
            ok("Tests have been executed")

        # ,app-package
        #   Build an application package
        elif prop == ",app-package":
            package = App.package()
            ok("A package for the application has been built", f"package: {package}")

        # ,app-clean
        #   Delete all generated files
        elif prop == ",app-clean":
            Frontend.clean()
            Db.clean()
            Backend.clean()
            root = Fs.root()
            for item in list(root.glob("_*")):
                if item.is_dir():
                    shutil.rmtree(item, ignore_errors=True)
            ok("ROOT directory cleaned", f"ROOT={root}")

        # SUPPORT #

        # ,guix-repl
        #   Start the Guix repl
        elif prop == ",guix-repl":
            Guix.repl(guix)

        # ,ssh-connect-dev-vm Port
        #   Connect to the init VM
        elif prop == ",ssh-connect-dev-vm":
            ssh_port = Params.port_check(params, 0)
            ip = Ip.mk("127.0.0.1")
            Ssh.connect(ssh, "root", Authority.mk(ip, ssh_port))

        # ,experiment
        #   Execute temporary code
        elif prop == ",experiment":
            App.service()

        # ,apply-static-tools-python [path]
        #   Apply static code tools to path or all python code
        elif prop == ",apply-static-tools-python":
            maybe = Params.string(params, 0)
            path = Maybe.elim(".", lambda string: string)(maybe)
            python = self._root / "python"

            try:
                Cmd.run_if_exists(["ruff", "format", path], cwd=python)
            except Exception:
                pass

            try:
                Cmd.run_if_exists(["ruff", "check", "--fix", path], cwd=python)
            except Exception:
                pass

            try:
                Cmd.run_if_exists(["uv", "run", "pyright", path], cwd=python)
            except Exception:
                pass

            try:
                Cmd.run_if_exists(
                    ["uv", "run", "pydeps", "lib/clocks", "-o", "/tmp/clocks-deps.png"],
                    cwd=python,
                )
            except Exception:
                pass

        else:
            Check.failed("Unexpected message.", f"message: {msg}")
