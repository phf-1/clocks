;;; lar--Overlayer.el --- Overlay management for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:ed895cdf-0f98-472c-95d0-dba6780d05b9][specification]]

;;; Code:

(require 'lar--send)
(require 'lar--Check)
(require 'lar--Error)
(require 'lar--Link)
(require 'lar--Overlay)
(require 'lar--Tag)
(require 'lar--Ui)

(defun lar--Overlayer (msg)
  "Actor for creating and removing UI overlays."
  (pcase msg
    (`(:mk ,searcher)
     (lambda (msg)
       (pcase msg
         (`(:add ,buffer ,link)
          (lar--buffer #'lar--Check buffer)

          (let ((start (lar--start link))
                (end (lar--end link))
                (tag (lar--tag link))
                (id (lar--id link))
                (name (lar--name link)))
            (lar--mk #'lar--Overlay buffer start end tag id name searcher))

          buffer)

         (`(:clean ,buffer)
          (lar--buffer #'lar--Check buffer)
          (with-current-buffer buffer
            (remove-overlays (point-min) (point-max) (lar--tag #'lar--Overlay) t))
          buffer)

         (_ (lar--unexpected #'lar--Error msg)))))
    (_ (lar--unexpected #'lar--Error msg))))

(provide 'lar--Overlayer)
;;; lar--Overlayer.el ends here
