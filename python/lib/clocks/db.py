# Specification

# [[id:54b11ca0-d89d-4940-8295-e63f1ca94546][db]]
#
# This module represents the database.
#
# root      : Directory
# dev_port  : Port
# test_port : Port
# prod_port : Port
# port : Mode → Port
# url  : Mode → Url
# mode_data : Mode → Directory
# mode_log  : Mode → Directory
# init      : Mode → Directory  (initialize the db data directory if needed)
# start     : Mode → ∅          (given an initialized dir, start the db)
# clean     : ∅                  (delete all db data)

# Implementation

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from clocks.check import Check
from clocks.fs import Fs
from clocks.port import Port
from clocks.mode import Mode
from clocks.constant import Constant

ENCODING = Constant.encoding()

_DEV_PORT  = Port.mk(5432)
_TEST_PORT = Port.mk(5433)
_PROD_PORT = Port.mk(5434)

# Interface

class Db:
    @staticmethod
    def root() -> Path:
        p = Fs.root() / "_postgresql"
        p.mkdir(parents=True, exist_ok=True)
        return p

    @staticmethod
    def port(mode):
        return Mode.elim(_DEV_PORT, _TEST_PORT, _PROD_PORT)(mode)

    @staticmethod
    def url(mode):
        port = Db.port(mode)
        return f"ecto://postgres@localhost:{port}/clocks_{mode}"

    @staticmethod
    def mode_data(mode) -> Path:
        Mode.check(mode)
        p = Db.root() / f"{mode}" / "data"
        p.parent.mkdir(parents=True, exist_ok=True)
        return p

    @staticmethod
    def mode_log(mode) -> Path:
        Mode.check(mode)
        p = Db.root() / f"{mode}" / "log"
        p.parent.mkdir(parents=True, exist_ok=True)
        return p

    @staticmethod
    def init(mode) -> Path:
        Mode.check(mode)
        db_data = Db.mode_data(mode)
        if not (db_data / "PG_VERSION").exists():
            db_data.mkdir(parents=True, exist_ok=True)
            result = subprocess.run([
                "initdb", "-D", str(db_data),
                "--auth=trust", "--username=postgres", "--encoding=UTF8",
            ])
            if result.returncode != 0:
                Check.failed("initdb failed", f"db_data={db_data}")
        return db_data

    @staticmethod
    def status(mode) -> None:
        Mode.check(mode)
        db_data = Db.mode_data(mode)
        status = subprocess.run(
            ["pg_ctl", "-D", str(db_data), "status"],
            capture_output=True,
        )
        if status.returncode == 0:
            return ["running", status.stdout.decode(ENCODING)]
        else:
            return ["stopped", "The database is not running"]

    @staticmethod
    def start(mode) -> None:
        Mode.check(mode)
        match Db.status(mode):
            case ["running", _status]:
                return # already running

            case _:
                db_data = Db.mode_data(mode)
                db_log  = Db.mode_log(mode)
                db_port = Db.port(mode)
                result = subprocess.run([
                    "pg_ctl", "-D", str(db_data),
                    "-l", str(db_log),
                    "-o", f"-p {db_port} -k /tmp",
                    "start",
                ])
                if result.returncode != 0:
                    Check.failed(
                        "Could not start PostgreSQL",
                        f"db_data={db_data}",
                        f"db_log={db_log}",
                        f"db_port={db_port}",
                    )

    @staticmethod
    def clean() -> None:
        shutil.rmtree(Db.root(), ignore_errors=True)
