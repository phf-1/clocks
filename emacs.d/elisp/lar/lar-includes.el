;;; lar-includes.el --- Generate #+include lines for ref links -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; Given the current org-mode buffer, resolve every :ref link via ripgrep and
;; write a corresponding #+include line into a fresh output buffer.
;; Unresolvable references are logged as errors.

;;; Code:

(require 'lar--Configuration)
(require 'lar--send)
(require 'lar--parser)
(require 'lar--searcher)
(require 'lar--Tag)

;; ---------------------------------------------------------------------------
;; Internal helpers
;; ---------------------------------------------------------------------------

(defun lar--includes-mode-suffix (filepath)
  "Return the Org #+include language suffix for FILEPATH, or nil if unknown.
For example \"/foo/bar.ex\" → \"elixir\", \"/foo/bar.py\" → \"python\"."
  (let ((ext (and filepath
                  (file-name-extension filepath))))
    (pcase ext
      ("R"     "r")
      ("bash"  "bash")
      ("c"     "c")
      ("cc"    "c++")
      ("clj"   "clojure")
      ("cljs"  "clojure")
      ("cpp"   "c++")
      ("css"   "css")
      ("el"    "emacs-lisp")
      ("ex"    "elixir")
      ("exs"   "elixir")
      ("go"    "go")
      ("h"     "c")
      ("heex"    "heex")
      ("hpp"   "c++")
      ("hs"    "haskell")
      ("html"  "html")
      ("java"  "java")
      ("js"    "js")
      ("json"  "json")
      ("jsx"   "js")
      ("kt"    "kotlin")
      ("lua"   "lua")
      ("md"    "markdown")
      ("ml"    "ocaml")
      ("mli"   "ocaml")
      ("org"   "org")
      ("py"    "python")
      ("r"     "r")
      ("rb"    "ruby")
      ("rs"    "rust")
      ("scala" "scala")
      ("sh"    "bash")
      ("sql"   "sql")
      ("swift" "swift")
      ("toml"  "toml")
      ("ts"    "typescript")
      ("tsx"   "typescript")
      ("xml"   "xml")
      ("yaml"  "yaml")
      ("yml"   "yaml")
      ("zsh"   "bash")
      (_       nil))))

(defun lar--includes-make-include-line (root result)
  "Build a #+include string from ROOT and a searcher RESULT (path line col)."
  (pcase-let ((`(,abs-or-rel ,_line ,_col) result))
    (let* ((abs-path  (expand-file-name abs-or-rel))
           (rel-path  (file-relative-name abs-path root))
           (suffix    (lar--includes-mode-suffix rel-path)))
      (if suffix
          (format "#+include: \"%s\" src %s" rel-path suffix)
        (format "#+include: \"%s\"" rel-path)))))

;; ---------------------------------------------------------------------------
;; Core iterative logic (async, driven by ripgrep callbacks)
;; ---------------------------------------------------------------------------

(defun lar--includes-process-links (links root searcher out-buf error-buf seen-paths)
  "Iterate over LINKS, search each ref-link, and write results.

LINKS      – list of lar--Link objects (all :ref, from lar--parser).
ROOT       – project root directory string.
SEARCHER   – an instantiated lar--Searcher actor.
OUT-BUF    – output buffer for #+include lines.
ERROR-BUF  – buffer for error messages.
SEEN-PATHS – hash table (equal) of absolute paths already written; updated
             in place so that two distinct IDs resolving to the same file
             produce only one #+include line."
  (if (null links)
      ;; All links processed — display output buffer.
      (progn
        (with-current-buffer out-buf
          (goto-char (point-min)))
        (pop-to-buffer out-buf))

    (let* ((link (car links))
           (rest (cdr links))
           (id   (lar--id link)))

      (let ((regex (lar--regex #'lar--parser :loc id)))
        (lar--search searcher regex
                     (lambda (results)
                       (cond
                        ((and results (= (length results) 1))
                         (let* ((abs-path (expand-file-name (car (car results)))))
                           (unless (gethash abs-path seen-paths)
                             (puthash abs-path t seen-paths)
                             (let ((line (lar--includes-make-include-line root (car results))))
                               (with-current-buffer out-buf
                                 (insert line "\n"))))))

                        ((null results)
                         (with-current-buffer error-buf
                           (insert (format "ERROR: no match for ref:%s\n" id))))

                        (t
                         ;; More than one result is ambiguous — log all candidates.
                         (with-current-buffer error-buf
                           (insert (format "ERROR: ambiguous ref:%s — %d matches:\n" id (length results)))
                           (dolist (r results)
                             (insert (format "  %s:%d:%d\n"
                                             (expand-file-name (car r))
                                             (cadr r)
                                             (caddr r)))))))

                       ;; Continue with the remaining links after the callback.
                       (lar--includes-process-links rest root searcher out-buf error-buf seen-paths)))))))

;; ---------------------------------------------------------------------------
;; Public interactive command
;; ---------------------------------------------------------------------------

;;;###autoload
(defun lar-includes ()
  "Generate #+include lines for every :ref link in the current buffer.

For each [[ref:ID][…]] (or equivalent) link found in the buffer, search
the project for the matching id:ID declaration via ripgrep and write a
corresponding #+include line into a new *lar-includes* buffer.

The path is expressed relative to the project root so that the resulting
snippet is portable.  When the file extension is recognised, a src block
language suffix is appended:

    #+include: \"path/to/file.ex\" src elixir

Unresolvable or ambiguous references are reported in *lar-includes-errors*."
  (interactive)
  (let* ((buf       (current-buffer))
         (root      (lar--root #'lar--Configuration))
         (rg-path   (lar--rg   #'lar--Configuration))
         (searcher  (lar--mk   #'lar--Searcher root rg-path))
         (links     (lar--links #'lar--parser buf))
         (out-buf   (get-buffer-create "*lar-includes*"))
         (error-buf (get-buffer-create "*lar-includes-errors*")))

    ;; Prepare output buffer.
    (with-current-buffer out-buf
      (read-only-mode -1)
      (erase-buffer)
      (org-mode))

    ;; Prepare error buffer.
    (with-current-buffer error-buf
      (read-only-mode -1)
      (erase-buffer))

    ;; Keep only :ref links.  Path-level deduplication happens inside
    ;; lar--includes-process-links via the seen-paths hash table: two
    ;; different IDs that resolve to the same file produce only one line.
    (let* ((ref-links  (seq-filter (lambda (l) (eq (lar--tag l) :ref)) links))
           (seen-paths (make-hash-table :test #'equal)))

      (message "lar-includes: %d ref link(s) in %s …"
               (length ref-links)
               (buffer-name buf))

      (lar--includes-process-links ref-links root searcher out-buf error-buf seen-paths))))

(provide 'lar-includes)
;;; lar-includes.el ends here
