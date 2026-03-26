;;; lar--Check.el --- Validation actors for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:20b42aec-e678-4c24-8934-28ffef83b982][specification]]

;;; Code:

(require 'lar--Error)
(require 'lar--send)

(defun lar--Check (msg)
  "Actor for type checking and validation."
  (let (result)
    (setq result
          (pcase msg
            (`(:posint ,obj)
             (or (and (integerp obj) (> obj 0))
                 "obj is not an integer such that obj > 0."))

            (`(:keyword ,obj)
             (or (keywordp obj)
                 "obj is not a keyword."))

            (`(:list ,obj)
             (or (listp obj)
                 "obj is not a list."))

            (`(:string ,obj)
             (or (stringp obj)
                 "obj is not a string."))

            (`(:buffer ,obj)
             (or (bufferp obj)
                 "obj is not a buffer."))

            (`(:directory ,obj)
             (or (file-directory-p obj)
                 "obj is not a directory."))

            (`(:executable ,obj)
             (or (file-executable-p obj)
                 "obj is not an executable."))

            (_ (lar--unexpected #'lar--Error msg))))

    (when (stringp result)
      (error (concat result " obj = %s") (cadr msg)))))

(provide 'lar--Check)
;;; lar--Check.el ends here
