;; [[ref:f37c9e20-2ccb-4f68-858f-df3068260078][Specification]]
;; [[id:ddced880-d052-4730-afd1-51fa39d7404c][Manifest]]

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
          c-utf8-locales
          ))

      (specifications->manifest
        '(
           "bash"
           "coreutils"
           "diffutils"
           "emacs-cape"
           "emacs-consult"
           "emacs-corfu"
           "emacs-corfu-terminal"
           "emacs-dired-sidebar"
           "emacs-embark"
           "emacs-expreg"
           "emacs-f"
           "emacs-geiser"
           "emacs-geiser-guile"
           "emacs-guix"
           "emacs-iedit"
           "emacs-magit"
           "emacs-marginalia"
           "emacs-modus-themes"
           "emacs-orderless"
           "emacs-org"
           "emacs-paredit"
           "emacs-pcre2el"
           "emacs-pgtk"
           "emacs-rg"
           "emacs-vertico"
           "emacs-yasnippet"
           "fd"
           "font-jetbrains-mono"
           "fontconfig"
           "gawk"
           "gcc-toolchain"
           "git"
           "gnupg"
           "grep"
           "guile"
           "guile-readline"
           "hunspell"
           "hunspell-dict-en-us"
           "inotify-tools"
           "less"
           "make"
           "node"
           "nss-certs"
           "openssh"
           "postgresql"
           "procps"
           "python"
           "python-lsp-server"
           "python-toolz"
           "qemu-minimal"
           "ripgrep"
           "rsync"
           "sed"
           "shellcheck"
           "shellcheck"
           "shfmt"
           "shfmt"
           "tree"
           "tree-sitter-bash"
           "tree-sitter-elisp"
           "tree-sitter-elixir"
           "tree-sitter-python"
           "tree-sitter-scheme"
           "util-linux"
           "which"
           )))))

;; So that: 'guix time-machine -m manifest.scm' works
manifest
