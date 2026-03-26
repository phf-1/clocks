;;; init.el -*- lexical-binding: t; -*-

;;; Startup
(setq inhibit-startup-screen t
      initial-scratch-message nil)

;;; UI
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(column-number-mode 1)
(show-paren-mode 1)

(load-theme 'modus-vivendi-tinted t) ; or modus-vivendi for dark

;;; Fonts & display
(setq-default line-spacing 2)
(setq truncate-lines t)

;;; Sane defaults
(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80)

(setq require-final-newline t
      sentence-end-double-space nil
      use-short-answers t         ; y/n instead of yes/no
      ring-bell-function 'ignore)

;;; Files
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;;; Org-mode
(setq org-hide-leading-stars t
      org-hide-emphasis-markers t
      org-pretty-entities t
      org-ellipsis " ▾")

(setq org-todo-keywords
      '((sequence "TODO(t)" "DOING(o)" "|" "DONE(d)" "CANCELLED(c)")))

(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c l") #'org-store-link)

;;; Yasnippet (built-in dir, no package needed if snippets are local)
(setq yas-snippet-dirs
      (list (file-name-concat user-emacs-directory "yasnippet")))

;;; lar
(add-to-list 'load-path (file-name-concat user-emacs-directory "elisp/lar"))
(require 'lar)
(defun lar-auto-reload () (add-hook 'after-save-hook #'lar-reload nil t))
(add-hook 'org-mode-hook #'lar-mode)
(add-hook 'prog-mode-hook #'lar-mode)
(add-hook 'prog-mode-hook #'lar-auto-reload)

;; mouse
(xterm-mouse-mode 1)

;;; Local config (machine-specific, not in version control)
(let ((local (expand-file-name "local.el" user-emacs-directory)))
  (when (file-exists-p local)
    (load local)))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(safe-local-variable-values
   '((org-confirm-babel-evaluate)
     (eval add-hook 'after-save-hook #'lar-reload nil t)
     (eval add-hook 'before-save-hook #'whitespace-cleanup nil t))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
