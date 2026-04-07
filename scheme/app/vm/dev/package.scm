;; Context

;; [[id:23d4f5b3-e1b4-4bdd-a726-01cb5c41dd04][Package]] :≡ https://guix.gnu.org/manual/devel/en/html_node/package-Reference.html#index-package
;; [[id:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]] :≡ [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][Distribution]]

;; Specification

;; [[id:2c987f55-f961-4d1f-9268-dee9264ce318]]
;; This modules exports package.
;; package is a [[ref:23d4f5b3-e1b4-4bdd-a726-01cb5c41dd04][Package]] for a [[ref:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]].

;; Implementation

(define-module (app vm dev package))

(use-modules
 (guix gexp)
 ((guix packages) #:prefix guix:)
 (guix build-system copy)
 (app env constant))

(define distribution
  (local-file
   "__DIST__"
   #:recursive? #t))

(define package
  (guix:package
   (name "app")
   (version "0.1.0")           ; TODO(2244): read that from mix.exs
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

;; Interface

(export package)
