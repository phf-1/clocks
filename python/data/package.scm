(define-module (clocks package))

(use-modules
 (guix gexp)
 (guix packages)
 (guix build-system copy))

(define-public clocks
  (package
   (name "clocks")
   (version "0.1.0")
   (source (local-file "__DIST__" #:recursive? #t))
   (build-system copy-build-system)
   (arguments (list #:install-plan ''(("dist/" "/"))
                    #:strip-binaries? #f
                    #:validate-runpath? #f))
   (synopsis "package for a [[ref:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]]")
   (description "package for a [[ref:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]]")
   (license #f)
   (home-page #f)))

clocks
