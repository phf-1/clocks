# [[id:76c6bba1-86f6-4a7a-aea2-e40dd404d873][App]]
#
# This module represents the application.

from __future__ import annotations
import os
import shutil
import tempfile
from mode import Mode
from backend import Backend
from frontend import Frontend
from guix import Guix

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

    """

def _os(package):
    raise NotImplementedError

class App:
    """
    package : Path :≡ Path to the application package
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
        package_tmp = os.path.join(app_tmp, "package.scm")
        with open(package_tmp, "w") as f:
            f.write(_package(dist))
        Guix.build(package_tmp)
        return package_tmp

    @staticmethod
    def service():
        raise NotImplementedError

    @staticmethod
    def os():
        raise NotImplementedError
