;;; lar--Error.el --- Error handling actors for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:4a7e700c-86aa-4892-8110-560b1c07ea1f][specification]]

;;; Code:

(defun lar--Error (msg)
  "Actor handling error signals."
  (pcase msg
    (`(:unexpected ,msg)
     (error "Unexpected message. msg = %s" msg))

    (_
     (error "Unexpected message. msg = %s" msg))))

(provide 'lar--Error)
;;; lar--Error.el ends here
