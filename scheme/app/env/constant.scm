;; Specification

;; [[id:7a5ba082-9f21-47b5-97f4-b1e29d6726c4]] 
;; This module defines a set of constants for all the scheme code, for instance the
;; project root directory path.

;; Implementation

(define-module (app env constant))

(use-modules (ice-9 popen)
             (ice-9 rdelim))

;; Interface

(define-public project-root
  (let* ((port (open-input-pipe "git rev-parse --show-toplevel"))
         (root (read-line port)))
    (close-pipe port)
    root))

(define-public ssh-root
  (string-append project-root "/ssh"))

;; This key is used to log into a local dev VM.
(define-public dev-public-key-path
  (string-append ssh-root "/ed25519.pub"))

(define-public backend-dist (string-append project-root "/phoenix/_build/prod/rel/dist"))
