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

;; Erlang must also carry debug_info — Dialyzer builds its PLT from
;; Erlang's own .beam files (OTP stdlib, kernel, etc.) and needs the
;; abstract_code chunk there too.
(define erlang-with-debug-info
  (package
    (inherit erlang)
    (name "erlang-with-debug-info")
    (arguments
     (substitute-keyword-arguments (package-arguments erlang)
       ;; Keep native binaries unstripped (separate concern, harmless to set).
       ((#:strip-binaries? _ #t) #f)
       ((#:phases phases '%standard-phases)
        #~(modify-phases #$phases
            (add-before 'build 'enable-debug-info
              (lambda _
                ;; erlc respects ERL_COMPILER_OPTIONS.
                ;; debug_info tells it to embed abstract_code in every
                ;; .beam it produces — exactly what Dialyzer requires.
                (setenv "ERL_COMPILER_OPTIONS" "debug_info")))))))))

(define elixir-with-debug-info
  (package
    (inherit elixir)
    (name "elixir-with-debug-info")
    ;; Override the erlang input to use our debug-info-enabled build.
    (inputs
     (modify-inputs (package-inputs elixir)
       (replace "erlang" erlang-with-debug-info)))
    (arguments
     (substitute-keyword-arguments (package-arguments elixir)
       ((#:strip-binaries? _ #t) #f)
       ((#:phases phases '%standard-phases)
        #~(modify-phases #$phases
            (add-before 'build 'enable-debug-info
              (lambda _
                ;; Elixir's own Makefile compiles its .beam files via erlc.
                ;; Setting this env var ensures elixir_erl_compiler.beam
                ;; and all other stdlib .beam files get abstract_code chunks,
                ;; which Dialyzer requires to build a usable PLT.
                (setenv "ERL_COMPILER_OPTIONS" "debug_info")))))))))

(concatenate-manifests
 (list
  (packages->manifest
   (list
    c-utf8-locales
    erlang-with-debug-info
    elixir-with-debug-info))

  (specifications->manifest
   '("nss-certs"
     "bash"
     "coreutils"
     "make"
     "gnupg"
     "git"
     "postgresql"
     "inotify-tools"
     "ripgrep"
     "fd"
     "tree"
     "sed"
     "emacs"
     "emacs-pcre2el"
     "openssh"
     "node"
     "rsync"
     "gcc-toolchain"
     "fontconfig"
     "util-linux"
     "gawk"
     "grep"
     "shellcheck"
     "shfmt"
     "which"))))
