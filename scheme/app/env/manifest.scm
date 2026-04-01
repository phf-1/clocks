;; Specification

;; [[id:ddced880-d052-4730-afd1-51fa39d7404c]] 
;; This module defines a [[ref:80e405db-329d-4dd1-a642-ed1bdb8e3a54][Manifest]] that provides the sub-set of available packages
;; within the provided [[ref:de35545c-ebb7-41db-b7c7-c8fcff0422f2][channel]].

;; Implementation

(define-module (app env channels))

(use-modules
 (guix packages)
 (guix utils)
 (gnu packages erlang)
 (gnu packages elixir)
 (gnu packages base)
 ((guix gexp) #:select (gexp)) 
 ((gnu packages) #:select (specifications->manifest))
 ((guix profiles) #:select (concatenate-manifests packages->manifest)))

(define c-utf8-locales
  (make-glibc-utf8-locales
   glibc
   #:locales (list "C")
   #:name "c-utf8-locales"))

;; Erlang must carry debug_info — Dialyzer builds its PLT from
;; Erlang's own .beam files and needs the abstract_code chunk there.
;; (define erlang-with-debug-info
;;   (package
;;    (inherit erlang)
;;    (name "erlang-with-debug-info")
;;    (arguments
;;     (substitute-keyword-arguments
;;      (package-arguments erlang)
;;      ((#:strip-binaries? _ #t) #f)
;;      ((#:phases phases '%standard-phases)
;;       #~(modify-phases #$phases
;;                        (add-before 'build 'enable-debug-info
;;                                    (lambda _
;;                                      (setenv "ERL_COMPILER_OPTIONS" "debug_info")))))))))

;; (define elixir-with-debug-info
;;   (package
;;    (inherit elixir)
;;    (name "elixir-with-debug-info")
;;    (inputs
;;     (modify-inputs (package-inputs elixir)
;;                    (replace "erlang" erlang-with-debug-info)))
;;    (arguments
;;     (substitute-keyword-arguments
;;      (package-arguments elixir)
;;      ((#:strip-binaries? _ #t) #f)
;;      ((#:phases phases '%standard-phases)
;;       #~(modify-phases #$phases
;;                        (add-before 'build 'enable-debug-info
;;                                    (lambda _
;;                                      (setenv "ERL_COMPILER_OPTIONS" "debug_info")))))))))

;; Interface

(define-public manifest
  (concatenate-manifests
   (list

    ;; ── Runtime ────────────────────────────────────────────────────────────────
    ;; (packages->manifest
    ;;  (list
    ;;   ;; erlang-with-debug-info
    ;;   ;; elixir-with-debug-info
    ;;   ))

    (specifications->manifest
     '( ;; TLS / certs
       "nss-certs"

       "erlang"
       "elixir"
       
       ;; Core shell environment
       "bash"
       "coreutils"
       "make"
       "gawk"
       "grep"
       "sed"
       "which"

       ;; Version control & deployment
       "git"
       "gnupg"
       "openssh"
       "rsync"

       ;; Database
       "postgresql"

       ;; Build toolchain
       "gcc-toolchain"
       "node"
       "guile"
       "qemu-minimal"

       ;; System libraries
       "fontconfig"
       "util-linux"

       ;; Dev tooling
       "inotify-tools"   
       "ripgrep"
       "fd"
       "tree"
       "less"
       "emacs"
       "emacs-pcre2el"
       "shellcheck"
       "shfmt"
       "guile-readline"
       "guile-colorized"       
       ))

    (packages->manifest
     (list c-utf8-locales)))))

;; So that: 'guix time-machine -m manifest.scm' works
manifest
