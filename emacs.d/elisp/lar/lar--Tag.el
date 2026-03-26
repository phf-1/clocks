;;; lar--Tag.el --- Tag type definitions for lar -*- lexical-binding: t; -*-
;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:089f64c7-0c56-40af-ae19-af444e163aa0][specification]]

;;; Code:

(require 'lar--Error)
(require 'lar--send)

(defun lar--Tag (msg)
  "Actor for managing link tags (loc/ref)."
  (pcase msg
    (`(:check ,obj)
     (unless (memq obj '(:loc :ref))
       (error "obj is not a Tag. obj = %s" obj)))
    (:loc :loc)
    (:ref :ref)
    ('(:inverse :loc) :ref)
    ('(:inverse :ref) :loc)
    ('(:string :ref) "ref")
    ('(:string :loc) "id")
    ('(:render :ref) "→")
    ('(:render :loc) "⊙")
    (_ (lar--unexpected #'lar--Error msg))))

(provide 'lar--Tag)
;;; lar--Tag.el ends here
