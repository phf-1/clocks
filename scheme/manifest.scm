;; [[id:ddced880-d052-4730-afd1-51fa39d7404c][Manifest]]
;;
;; The objective is to define Guix packages available in this environemnt.

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
(define erlang-with-debug-info
  (package
   (inherit erlang)
   (name "erlang-with-debug-info")
   (arguments
    (substitute-keyword-arguments
     (package-arguments erlang)
     ((#:strip-binaries? _ #t) #f)
     ((#:tests? _ #t) #f)
     ((#:phases phases '%standard-phases)
      #~(modify-phases #$phases
                       (add-before 'build 'enable-debug-info
                                   (lambda _
                                     (setenv "ERL_COMPILER_OPTIONS" "debug_info")))))))))

(define elixir-with-debug-info
  (package
   (inherit elixir)
   (name "elixir-with-debug-info")
   (inputs
    (modify-inputs (package-inputs elixir)
                   (replace "erlang" erlang-with-debug-info)))
   (arguments
    (substitute-keyword-arguments
     (package-arguments elixir)
     ((#:strip-binaries? _ #t) #f)
     ((#:tests? _ #t) #f)
     ((#:phases phases '%standard-phases)
      #~(modify-phases #$phases
                       (add-before 'build 'enable-debug-info
                                   (lambda _
                                     (setenv "ERL_COMPILER_OPTIONS" "debug_info")))))))))

(define manifest
  (concatenate-manifests
   (list

    (packages->manifest
     (list
      erlang-with-debug-info
      elixir-with-debug-info
      ))

    (specifications->manifest
     '(
       "bash"
       "coreutils"
       "elixir"
       "emacs"
       "emacs-pcre2el"
       "erlang"
       "fd"
       "fontconfig"
       "gawk"
       "gcc-toolchain"
       "git"
       "gnupg"
       "grep"
       "guile"
       "guile-colorized"
       "guile-readline"
       "inotify-tools"
       "less"
       "make"
       "node"
       "nss-certs"
       "openssh"
       "postgresql"
       "python"
       "python-toolz"
       "qemu-minimal"
       "ripgrep"
       "rsync"
       ;; "ruff"
       "sed"
       "shellcheck"
       "shfmt"
       "tree"
       "util-linux"
       "which"
       ))

    (packages->manifest
     (list c-utf8-locales)))))

;; So that: 'guix time-machine -m manifest.scm' works
manifest
