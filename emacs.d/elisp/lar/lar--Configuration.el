;;; lar--Configuration.el --- User configuration for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:3679aa4b-cb4b-40a5-a72a-a8cf95e3de99][specification]]

;;; Code:

(require 'project)  ; built-in project detection

(defgroup lar nil
  "Locate and print Org-style id/ref links."
  :group 'tools)

(defcustom lar-rg-path "rg"
  "Path to the ripgrep executable."
  :type 'string
  :group 'lar)

(defcustom lar-monorepo-marker ".project"
  "Filename that identifies the monorepo root (your architecture spec).
lar-mode will walk up the directory tree until it finds this file."
  :type 'string
  :group 'lar)

(defun lar--Configuration (msg)
  "Actor for configuration queries."
  (pcase msg
    (:rg (executable-find lar-rg-path))
    (:root (lar--compute-root))
    (_ (lar--unexpected #'lar--Error msg))))

(defun lar--compute-root ()
  "Return the true monorepo root.

Priority:
  1. Directory containing `lar-monorepo-marker'
  2. Standard Emacs project root (mix.exs, .git, etc.)
  3. Current buffer directory
  4. ~ as last resort"
  (expand-file-name
   (or
    ;; 1. Monorepo marker
    (locate-dominating-file default-directory lar-monorepo-marker)

    ;; 2. Standard project detection
    (when-let ((proj (project-current)))
      (project-root proj))

    ;; 3-4. Fallbacks
    default-directory
    "~")))

(provide 'lar--Configuration)
;;; lar--Configuration.el ends here
