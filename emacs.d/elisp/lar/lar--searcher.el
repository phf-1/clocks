;;; lar--searcher.el --- Ripgrep interface for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:f21cac9b-de52-43fe-85f2-5e63d2ab0043][specification]]

;;; Code:

(require 'lar--send)
(require 'lar--Check)
(require 'lar--Error)

(defun lar--Searcher-cmd-mk (root rg-path pattern)
  "Build ripgrep command list for PATTERN search under ROOT.
RG-PATH is the path to the ripgrep executable."
  (list rg-path
        "-u"
        "-i"
        "--block-buffered"
        "--color=never"
        "--column" "-o"
        "--no-heading" "-H"
        "--trim"
        pattern
        root))

(defun lar--Searcher-search-async (root rg-path pattern cb)
  "Search for PATTERN under ROOT using ripgrep.
Call CB with a list of (path line column) tuples when complete."
  (let ((results '())
        (output-buffer (generate-new-buffer " *lar-searcher-output*")))
    (make-process
     :name "lar-searcher"
     :buffer output-buffer
     :command (lar--Searcher-cmd-mk root rg-path pattern)
     :sentinel
     (lambda (process _event)
       (when (memq (process-status process) '(exit signal))
         (with-current-buffer (process-buffer process)
           (goto-char (point-min))
           (while (not (eobp))
             (let ((line (buffer-substring-no-properties
                          (line-beginning-position)
                          (line-end-position))))
               (when (string-match "^\\([^:]+\\):\\([0-9]+\\):\\([0-9]+\\):" line)
                 (push (list (match-string 1 line)
                             (string-to-number (match-string 2 line))
                             (string-to-number (match-string 3 line)))
                       results)))
             (forward-line 1)))
         (kill-buffer output-buffer)
         (funcall cb (nreverse results)))))))

(defun lar--Searcher (msg)
  "Actor for external file searching."
  (pcase msg
    (`(:mk ,root ,path)
     (lar--directory #'lar--Check root)
     (lar--executable #'lar--Check path)
     (lambda (msg)
       (pcase msg
         (`(:search ,pattern ,cb)
          (lar--Searcher-search-async root path pattern cb))
         (_ (lar--unexpected #'lar--Error msg)))))
    (_ (lar--unexpected #'lar--Error msg))))

(provide 'lar--searcher)
;;; lar--searcher.el ends here
