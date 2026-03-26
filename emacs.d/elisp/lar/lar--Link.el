;;; lar--Link.el --- Link data structure actors for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:de7de9e1-046c-4295-9560-da55718e1648][specification]]

;;; Code:

(require 'lar--send)
(require 'lar--Tag)
(require 'lar--Check)
(require 'lar--Error)

(defun lar--Link (msg)
  "Actor representing a parsed link."
  (pcase msg
    (`(:mk ,path ,start ,end ,tag ,id ,name)
     (lar--string #'lar--Check path)

     (lar--posint #'lar--Check start)
     (lar--posint #'lar--Check end)
     (unless (< start end) (error "start ≥ end"))

     (lar--check #'lar--Tag tag)

     (and (lar--string #'lar--Check id)
          (cond
           ((> (length str) 0) str)
           (t (error "Length of str is 0."))))

     (lar--string #'lar--Check name)

     (lambda (msg)
       (pcase msg
         (:path path)
         (:start start)
         (:end end)
         (:tag tag)
         (:id id)
         (:name (string-trim name))
         (_ (lar--unexpected #'lar--Error msg)))))

    (_ (lar--unexpected #'lar--Error msg))))

(provide 'lar--Link)
;;; lar--Link.el ends here
