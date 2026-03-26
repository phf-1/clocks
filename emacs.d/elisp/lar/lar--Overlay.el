;;; lar--Overlay.el --- Overlay management for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:7d158113-130f-41a8-9823-99db28fdef61][specification]]

;;; Code:

(require 'lar--send)
(require 'lar--Check)
(require 'lar--Error)
(require 'lar--parser)
(require 'lar--Link)
(require 'lar--Tag)
(require 'lar--Ui)

(defun lar--Overlay (msg)
  "Actor for creating and removing UI overlays."
  (pcase msg
    (`(:mk ,buffer ,start ,end ,tag ,id ,name ,searcher)
     (lar--buffer #'lar--Check buffer)
     (lar--posint #'lar--Check start)
     (lar--posint #'lar--Check end)
     (lar--check #'lar--Tag tag)
     (lar--string #'lar--Check id)
     (lar--string #'lar--Check name)
     (unless (< start end) (error "end ≥ start"))
     (with-current-buffer buffer
       (let ((ov (make-overlay start end buffer))
             (map (make-sparse-keymap)))

         (define-key map [mouse-1]
                     (lambda (_)
                       (interactive "e")
                       (let* ((inv-tag (lar--inverse #'lar--Tag tag))
                              (tag-str (lar--string #'lar--Tag inv-tag))
                              (regex (lar--regex #'lar--parser inv-tag id)))
                         (lar--search searcher regex
                                      (lambda (results)
                                        (if (and results (= (length results) 1))
                                            (pcase-let ((`(,path ,line ,col) (car results)))
                                              (let ((abs-path (expand-file-name path)))
                                                (find-file-other-window abs-path)
                                                (goto-line line)
                                                (recenter 5)
                                                (move-to-column (1- col))))
                                          (let ((ui (lar--mk #'lar--Ui)))
                                            (if results
                                                (lar--display ui results)
                                              (lar--display ui (format "No results found.\n  tag = %s\n  id = %s" tag-str id))))))))))

         (define-key map [mouse-3]
                     (lambda (_)
                       (interactive "e")
                       (let* ((inv-tag (lar--inverse #'lar--Tag tag))
                              (tag-str (lar--string #'lar--Tag inv-tag))
                              (link (if (and name (not (string-empty-p name)))
                                        (format "[[%s:%s][%s]]" tag-str id name)
                                      (format "[[%s:%s]]" tag-str id))))
                         (kill-new link)
                         (gui-set-selection 'PRIMARY link)
                         (gui-set-selection 'CLIPBOARD link)
                         (message "Copied: %s" link))))


         (overlay-put ov 'lar--Overlayer t)
         (overlay-put ov 'face 'link)
         (overlay-put ov 'mouse-face 'highlight)
         (overlay-put ov 'help-echo "Click to follow | Right-click to copy inverse link | Middle-click to yank")

         (let* ((rendered-tag (lar--render #'lar--Tag tag))
                (rendered-name (or (and (not (string-empty-p name)) name)
                                   (lar--string #'lar--Tag tag)))
                (rendered (format "%s%s" rendered-tag rendered-name)))
           (put-text-property 0 (length rendered) 'keymap map rendered)
           (overlay-put ov 'display rendered)))))

    (:tag 'lar--Overlayer)
    (_ (lar--unexpected #'lar--Error msg))))

(provide 'lar--Overlay)
;;; lar--Overlay.el ends here
