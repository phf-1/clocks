;;; .dir-locals.el -*- lexical-binding: t; no-byte-compile: t -*-
;;; ================================================
;;; Project-specific Emacs configuration
;;; ================================================
;;;
;;; This file is automatically loaded by Emacs whenever you open
;;; any file inside this directory tree.
;;;
;;; Features:
;;;   1. Loads ./emacs/elisp/extension.el (project-specific Lisp code)
;;;      → Perfect place for custom keybindings, mode hooks,
;;;        functions, variables, etc.
;;;   2. Adds ./emacs/yasnippet/ as a snippet directory
;;;      → Project snippets OVERRIDE global and personal ones.
;;;
;;; How it works:
;;;   - Uses `locate-dominating-file` so it works even if you open
;;;     a file deep inside a subdirectory.
;;;   - Everything is safe and silent (no errors if files are missing).
;;;
;;; For more information: (info "(emacs) Directory Variables")

((nil . ((eval . (let ((project-root (locate-dominating-file
                                      default-directory ".dir-locals.el")))
                   (when project-root
                     ;; =============================================
                     ;; 1. Load project-specific extension file
                     ;; =============================================
                     ;; This is your main project configuration file.
                     ;; Put anything you want here (keybindings, hooks, etc.).
                     (let ((extension-file (expand-file-name "emacs/elisp/extension.el" project-root)))
                       (load extension-file 'noerror 'nomessage))

                     ;; =============================================
                     ;; 2. Project-specific YASnippet support
                     ;; =============================================
                     (let ((snippets-dir (expand-file-name "emacs/yasnippet" project-root)))
                       (with-eval-after-load 'yasnippet
                         ;; Only proceed if the directory exists and is not already added
                         (when (and (file-directory-p snippets-dir)
                                    (not (member (file-name-as-directory snippets-dir)
                                                 yas-snippet-dirs)))
                           ;; Project snippets take priority (added at the front)
                           (add-to-list 'yas-snippet-dirs snippets-dir)
                           ;; Reload so new snippets are immediately available
                           (yas-reload-all)))))))))
