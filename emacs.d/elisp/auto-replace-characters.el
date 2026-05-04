;;; auto-replace-characters.el --- Minor mode for automatic string-to-symbol replacement -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Free Software Foundation, Inc.

;; Author: Pierre-Henry FRÖHRING
;; Version: 1.2
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, abbrev, unicode
;; URL: https://example.com/auto-replace-characters

;;; Commentary:
;;
;; This package provides a minor mode that automatically replaces
;; trigger strings (e.g. ",a") with Unicode symbols (e.g. "α") as you type.
;;
;; It is designed to be safe with undo, minibuffer, and other modes.
;;
;; Usage:
;;   (require 'auto-replace-characters)
;;   (global-auto-replace-characters-mode 1)
;;
;; Or enable per-buffer:
;;   (add-hook 'org-mode-hook #'auto-replace-characters-mode)
;;
;; Customize `auto-replace-characters-rules' for your own mappings.
;;
;; Rules are sorted by descending trigger length so that longer triggers
;; always take precedence over shorter ones (e.g. ",---" beats ",--").
;; The sort is applied both at load time and whenever the variable is
;; changed via `customize'.

;;; Code:

(require 'cl-lib)

(defgroup auto-replace-characters nil
  "Automatic replacement of trigger strings with symbols."
  :group 'convenience
  :prefix "auto-replace-characters-")

(defcustom auto-replace-characters-include-minibuffer nil
  "If non-nil, perform replacements in the minibuffer too.
Default is nil because changing text in the minibuffer can interfere
with completions and special minibuffer behavior."
  :type 'boolean
  :group 'auto-replace-characters)

(defun auto-replace-characters--sort-rules (rules)
  "Return a copy of RULES sorted by descending trigger length."
  (sort (copy-sequence rules)
        (lambda (a b) (> (length (car a)) (length (car b))))))

(defcustom auto-replace-characters-rules
  ;; The literal value is already in the order the user wrote it.
  ;; :initialize calls :set, so the sorted order is established at load time.
  '((",:"   . "→")
    (",iso" . "≅")
    (",|-"  . "⊢")
    (",..." . "…")
    (",a"   . "α")
    (",b"   . "β")
    (",x"   . "×")
    (",;"   . ":≡")
    (",--"  . "—")   ; must sort after ",---"
     (",---" . "≡")   ; must sort before ",--"
    (",fa"  . "∀")
    (",phi" . "φ")
    ("/="   . "≠")
    (",0/"  . "∅")
    (",>="  . "≥")
    (",=<"  . "≤")
    (",in"  . "∈")
    (",<-"  . "←")
    (",=>"  . "⇒")
    (",<="  . "⇐")
    (",la"  . "λ")
    (",!"   . "↓")
    (",>"   . "▸")
    (",h"   . "🞎")
    (",s"   . "■")
    (",l"   . "↦")
    (",|>"  . "▸")
    (",ie"  . "/i.e./")
    (",eg"  . "/e.g./")
    (",k"   . "⇝"))
  "Alist of (TRIGGER . REPLACEMENT).
When TRIGGER appears immediately before point, it is replaced by REPLACEMENT.
Rules are automatically sorted so that longer triggers take precedence over
shorter ones (e.g. \",---\" fires before \",--\")."
  :type '(alist :key-type string :value-type string)
  :group 'auto-replace-characters
  ;; :initialize 'custom-initialize-set ensures the :set function runs at
  ;; load time (not only when the user saves via Customize), so the sort
  ;; invariant holds from the very first use of the variable.
  :initialize #'custom-initialize-set
  :set (lambda (sym val)
         (set-default sym (auto-replace-characters--sort-rules val))))

(defvar auto-replace-characters--replacing nil
  "Non-nil while a replacement is in progress.
Prevents re-entrant calls from `post-self-insert-hook'.")

(defun auto-replace-characters--corfu-active-p ()
  "Return non-nil when a Corfu completion popup is currently visible."
  (and (bound-and-true-p corfu-mode)
       (bound-and-true-p corfu--candidates)
       corfu--candidates))

(defun auto-replace-characters--post-self-insert ()
  "Replace the trigger string before point according to `auto-replace-characters-rules'.

This function is added to `post-self-insert-hook'.  It is a no-op when:
- a replacement is already in progress (re-entrance guard),
- the buffer is read-only,
- the current buffer is the minibuffer and
  `auto-replace-characters-include-minibuffer' is nil,
- a Corfu completion popup is currently visible (to avoid disrupting
  the user's selection)."
  (when (and (not auto-replace-characters--replacing)
             (not buffer-read-only)
             (or auto-replace-characters-include-minibuffer
                 (not (minibufferp)))
             (not (auto-replace-characters--corfu-active-p)))
    (when-let ((rule (auto-replace-characters--find-matching-rule)))
      (let ((trigger-len (length (car rule)))
            (replacement (cdr rule)))
        (let ((start (- (point) trigger-len)))
          (setq auto-replace-characters--replacing t)
          ;; Use a change group amalgamated with the preceding self-insert so
          ;; that a single C-/ (undo) restores the pre-replacement state,
          ;; including all trigger characters, in one step.
          (let ((change-group (prepare-change-group)))
            (activate-change-group change-group)
            (unwind-protect
                (progn
                  (delete-region start (point))
                  (insert replacement)
                  (accept-change-group change-group)
                  (undo-amalgamate-change-group change-group))
              (setq auto-replace-characters--replacing nil))))))))

(defun auto-replace-characters--find-matching-rule ()
  "Return the first (longest) rule whose trigger matches text before point.
Rules in `auto-replace-characters-rules' are sorted by descending trigger
length, so the first match is always the longest match."
  (cl-loop for rule in auto-replace-characters-rules
           for trigger = (car rule)
           for len = (length trigger)
           when (and (>= (point) len)
                     (string= (buffer-substring-no-properties
                               (- (point) len) (point))
                              trigger))
           return rule))

;;;###autoload
(define-minor-mode auto-replace-characters-mode
  "Minor mode: replace strings like \",a\" with symbols as you type.
See `auto-replace-characters-rules' for customization."
  :lighter " ARC"
  :group 'auto-replace-characters
  (if auto-replace-characters-mode
      (add-hook 'post-self-insert-hook
                #'auto-replace-characters--post-self-insert nil t)
    (remove-hook 'post-self-insert-hook
                 #'auto-replace-characters--post-self-insert t)))

;;;###autoload
(define-globalized-minor-mode global-auto-replace-characters-mode
  auto-replace-characters-mode
  (lambda ()
    (when (or auto-replace-characters-include-minibuffer
              (not (minibufferp)))
      (auto-replace-characters-mode 1))))

(provide 'auto-replace-characters)
;;; auto-replace-characters.el ends here
