(use-modules (gnu packages base))

(define c-utf8-locales
  (make-glibc-utf8-locales
   glibc
   #:locales (list "C")
   #:name "c-utf8-locales"))

(use-modules (guix packages)
             (guix utils)
             (gnu packages erlang)
             (gnu packages elixir))

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
     ((#:phases phases '%standard-phases)
      #~(modify-phases #$phases
                       (add-before 'build 'enable-debug-info
                                   (lambda _
                                     (setenv "ERL_COMPILER_OPTIONS" "debug_info")))))))))

(concatenate-manifests
 (list

  ;; ── Runtime ────────────────────────────────────────────────────────────────
  (packages->manifest
   (list
    erlang-with-debug-info
    elixir-with-debug-info))

  (specifications->manifest
   '(;; TLS / certs
     "nss-certs"

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

     ;; System libraries
     "fontconfig"
     "util-linux"

     ;; Dev tooling
     "inotify-tools"   
     "ripgrep"
     "fd"
     "tree"
     "emacs"
     "emacs-pcre2el"
     "shellcheck"
     "shfmt"
     ))

  (packages->manifest
   (list c-utf8-locales))))
