;;; lar--parser.el --- PEG parser for lar links -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:c7d70791-dcbb-4808-a6e1-9d1a9260fbbb][specification]]

;;; Code:

(require 'lar--send)
(require 'lar--Check)
(require 'lar--Error)
(require 'lar--Link)
(require 'lar--Tag)
(require 'peg)
(require 'rx)
(require 'pcre2el)

(define-peg-ruleset lar--link-grammar
  (link () `(-- (point)) (or global property inline) `(-- (point)))
  (global () (bol) "#+" tag ":" (* space) (substring id) (opt (+ space) (substring name)))
  (property () (bol) ":" tag ":" (* space) (substring id) (opt (+ space) (substring name)))
  (inline () "[" "[" tag ":" (substring id) "]" (opt "[" (opt (substring name)) "]") "]")
  (id () (+ alpha))
  (name () (+ (or alpha " " ":" ">" "<" "→")))
  (tag () (or loc ref))
  (loc () (or "id" "ID") `(-- :loc))
  (ref () (or "ref" "REF") `(-- :ref))
  (alpha () (or letter LETTER digit "_" "-" "." "/"))
  (LETTER () [A-Z])
  (letter () [a-z])
  (digit () [0-9])
  (space () " "))

(defun lar--parser-peg-parse ()
  "Internal function to run the PEG parser."
  (nreverse
   (with-peg-rules (lar--link-grammar)
     (peg-run (peg link)))))

(defun lar--parser (msg)
  "Actor for parsing links and generating regexes."
  (pcase msg
    (`(:links ,buffer)
     (lar--buffer #'lar--Check buffer)
     (with-current-buffer buffer
       (let (links)
         (save-excursion
           (goto-char (point-min))
           (while (not (eobp))
             (pcase (lar--parser-peg-parse)
               (`(,start ,tag ,id ,end)
                (push
                 (lar--mk #'lar--Link (buffer-file-name) start end tag id "")
                 links))
               (`(,start ,tag ,id ,name ,end)
                (push
                 (lar--mk #'lar--Link (buffer-file-name) start end tag id name)
                 links))
               (_ (forward-char 1)))))
         (nreverse links))))

    (`(:regex ,tag ,id)
     (lar--check #'lar--Tag tag)
     (lar--string #'lar--Check id)
     (let ((tag-str (lar--string #'lar--Tag tag)))
       (rxt-elisp-to-pcre
        (rx-to-string
         `(or
           (seq bol "#+" (or ,tag-str ,(upcase tag-str)) ":" (* space) ,id)
           (seq bol ":" (or ,tag-str ,(upcase tag-str)) ":" (* space) ,id)
           (seq "[[" (or ,tag-str ,(upcase tag-str)) ":" ,id "]" (opt "[" (* (not (any "]"))) "]") "]"))
         t))))

    (_ (lar--unexpected #'lar--Error msg))))

(provide 'lar--parser)
;;; lar--parser.el ends here
