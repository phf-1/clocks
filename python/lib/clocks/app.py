# [[id:76c6bba1-86f6-4a7a-aea2-e40dd404d873][App]]
#
# This module represents the application.

from __future__ import annotations

import tempfile
from pathlib import Path

from clocks.backend import Backend
from clocks.frontend import Frontend
from clocks.guix import Guix
from clocks.mode import Mode
from clocks.osys import Osys


def _package(dist):
    return f"""
(use-modules
 (guix gexp)
 ((guix packages) #:prefix guix:)
 (guix build-system copy))

(define distribution
  (local-file
   "{dist}"
   #:recursive? #t))

(define-public package
  (guix:package
   (name "app")
   (version "0.1.0")                    ; TODO(2244): read that from mix.exs
   (source distribution)
   (build-system copy-build-system)
   (arguments
    (list
     #:install-plan
     ''(("./" "opt/app"))))
   (synopsis "package for a [[ref:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]]")
   (description "package for a [[ref:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]]")
   (license #f)
   (home-page #f)))

package
"""


def _service(package):
    return """
;; Given that application package is installed on the current system, then define a
;; Shepherd service that starts the application, and connect application logs to
;; syslogd.

;;
    """


def _os(package):
    return """
;; Given an application package and associated service, then define an os that starts
;; the support services for tha application to run: database, syslogd, nginx, ….
    """


class App:
    """package : Path :≡ Path to the application package
    service : Path :≡ Path to the service
    os : Path :≡ Path to the os
    """

    @staticmethod
    def package():
        mode = Mode.prod()
        url = Backend.url(mode)
        frontend_dist = Frontend.dist(url)
        dist = Backend.dist(frontend_dist)
        app_tmp = tempfile.mkdtemp(prefix="app_")
        package_tmp = Path(app_tmp) / "package.scm"
        with open(package_tmp, "w") as f:
            f.write(_package(dist))

        # TODO(910d): Refactor
        guix = Guix()
        Guix.build(guix, package_tmp)
        return package_tmp

    @staticmethod
    def service():
        print("service")

    @staticmethod
    def os():
        return Osys.dev()
