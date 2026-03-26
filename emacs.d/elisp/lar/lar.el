;;; lar.el --- Define locations and references for files and buffers -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; Maintainer: Pierre-Henry FRÖHRING contact@phfrohring.com
;; Homepage: https://github.com/phf-1/lar
;; Package-Version: 0.20
;; Package-Requires: ((emacs "29.1") (peg "1.0"))
;; Keywords: tools, hypermedia
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:fab21ab9-754d-4331-be62-9790112b18b2][specification]]

;;; Commentary:

;; Define and navigate Org-style ID and REF links across files and buffers.
;; This mode scans the current buffer for links and provides interactive
;; overlays to search for occurrences using ripgrep.

;;; Code:

(require 'lar--Configuration)
(require 'lar--send)
(require 'lar--parser)
(require 'lar--searcher)
(require 'lar--Overlayer)

(defun lar--emacs-start ()
  "Clean previous overlays and add fresh ones to the current buffer."
  (let* ((root (lar--root #'lar--Configuration))
         (rg-path (lar--rg #'lar--Configuration))
         (searcher (lar--mk #'lar--Searcher root rg-path))
         (overlayer (lar--mk #'lar--Overlayer searcher))
         (buffer (progn (let ((b (current-buffer))) (lar--clean overlayer b) b)))
         (links (lar--links #'lar--parser buffer)))
    (message "root = %s (from lar-mode)" root)
    (dolist (link links) (lar--add overlayer buffer link))))

(defun lar--emacs-stop ()
  "Remove all overlays added by lar-mode."
  (lar--clean
   (lar--mk #'lar--Overlayer nil)
   (current-buffer)))

(defun lar-reload ()
  (interactive)
  (lar--emacs-stop)
  (lar--emacs-start))

;;;###autoload
(define-minor-mode lar-mode
  "Locate and print Org-style id/ref links."
  :global nil
  :lighter " Lar"
  (if lar-mode
      (lar--emacs-start)
    (lar--emacs-stop)))

(provide 'lar)
;;; lar.el ends here
