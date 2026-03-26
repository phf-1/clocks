;;; lar--Ui.el --- Search results UI for lar -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:11058c38-1c3f-4400-934a-b4b9afa7ceb9][specification]]

;;; Code:

(require 'lar--send)
(require 'lar--Check)
(require 'lar--Error)

(defun lar--Ui (msg)
  "Actor for managing the search results frame and buffer."
  (pcase msg
    (:mk
     (let (frame window buffer delete-buffer)
       (setq buffer (generate-new-buffer "*lar-search-results*"))
       (setq frame (make-frame '((name . "LAR Search Results")
                                 (width . 160)
                                 (height . 40))))
       (setq window (frame-selected-window frame))

       ;; If the frame is closed, then delete the buffer.
       (setq delete-buffer
             (lambda (f)
               (when (eq f frame)
                 (remove-hook 'delete-frame-functions delete-buffer)
                 (when (buffer-live-p buffer)
                   (kill-buffer buffer)))))
       (add-hook 'delete-frame-functions delete-buffer)

       (with-selected-window window
         (switch-to-buffer buffer)
         (grep-mode)
         (let ((inhibit-read-only t))
           (insert "Searching …\n\n")))

       (lambda (msg)
         (pcase msg
           (:stop
            (when (buffer-live-p buffer)
              (kill-buffer buffer))
            (when (frame-live-p frame)
              (delete-frame frame)))

           ((and `(:display ,links) (guard (listp links)))
            (with-current-buffer buffer
              (let ((inhibit-read-only t))
                (erase-buffer)
                (insert "Search results:\n\n")
                (dolist (link links)
                  (pcase-let ((`(,path ,line ,col) link))
                    (let ((abs-path (expand-file-name path)))
                      (insert (format "%s:%d:%d\n" abs-path line col)))))
                (goto-char (point-min)))))

           ((and `(:display ,message) (guard (stringp message)))
            (with-current-buffer buffer
              (let ((inhibit-read-only t))
                (erase-buffer)
                (goto-char (point-min))
                (insert (format "%s" message)))))
           (_ (lar--unexpected #'lar--Error msg))))))
    (_ (lar--unexpected #'lar--Error msg))))

(provide 'lar--Ui)
;;; lar--Ui.el ends here
