;; -*- lexical-binding: t; -*-

;;; Emacs init.el
;;; Each comment states *what* is true after the form below it runs.
;;; The file is linear: every section may rely on what came before it.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Startup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'load-path (file-name-concat user-emacs-directory "elisp"))

;; The startup screen, echo-area banner, and scratch-buffer message are
;; suppressed — Emacs opens directly to a clean state.
(setq inhibit-startup-message t
  inhibit-startup-echo-area-message t
  initial-scratch-message nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Sound
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The audible/visible bell is silenced entirely.
(setq ring-bell-function 'ignore)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; User-Interface chrome
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The toolbar, menu bar, and scroll bar are hidden, leaving only the buffer.
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; The frame title shows the current buffer name instead of "GNU Emacs".
(setq frame-title-format '("%b — Emacs"))

;; which-key is active: pressing an incomplete key sequence shows
;; a popup listing all possible completions.
(require 'which-key)
(which-key-mode 1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Editing defaults
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Indentation uses spaces (never tabs), with a width of 2 columns.
;; Lines wrap visually at 80 characters.
(setq-default indent-tabs-mode nil
        tab-width 2
        fill-column 90)

;; Typing over an active region replaces it (standard selection behaviour).
(delete-selection-mode 1)
(require 'expreg)
(global-set-key (kbd "C-<") #'expreg-expand)


;; Long lines wrap visually at the window edge rather than being truncated.
(global-visual-line-mode 1)

;; A single space ends a sentence, so fill commands work correctly.
(setq sentence-end-double-space nil)

(require 'auto-replace-characters)
(add-hook 'org-mode-hook  #'auto-replace-characters-mode)
(add-hook 'prog-mode-hook #'auto-replace-characters-mode)

;; Stop Emacs from asking retarted questions
(setq disabled-command-function nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Memory & subprocess I/O
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The GC threshold is raised to 100 MiB, and the LSP read buffer to 1 MiB,
;; reducing GC pauses during heavy editing and fast subprocess output.
(setq gc-cons-threshold (* 100 1024 1024)
  read-process-output-max (* 1024 1024))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Native compilation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; If native compilation is available, async warnings are suppressed so they
;; do not interrupt the editing session.
(when (and (fboundp 'native-comp-available-p)
     (native-comp-available-p))
  (setq native-comp-async-report-warnings-errors 'silent))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Files, backups, and auto-saves
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Buffers are automatically reverted when their file changes on disk.
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

;; Backup files are written to ~/.emacs.d/backups/ (not next to the original).
(defvar this-backup-dir (concat user-emacs-directory "backups/"))
(make-directory this-backup-dir t)

;; Auto-save files are written to ~/.emacs.d/auto-saves/.
(defvar this-auto-save-dir (concat user-emacs-directory "auto-saves/"))
(make-directory this-auto-save-dir t)

;; Backups are copied (not renamed), lock files are disabled, and the last
;; 5 new / 2 old versions are kept.
(setq backup-directory-alist `(("." . ,this-backup-dir))
      auto-save-file-name-transforms `((".*" ,this-auto-save-dir t))
      create-lockfiles nil
      backup-by-copying t
      delete-old-versions t
      kept-new-versions 5
      kept-old-versions 2)

;; Minibuffer history is saved across sessions.
(savehist-mode 1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Navigation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The current line is highlighted in every buffer.
(global-hl-line-mode 1)

;; Recently visited files are remembered (up to 200).
(recentf-mode 1)
(setq recentf-max-saved-items 200)

;; Point position is restored when a file is revisited.
(save-place-mode 1)

;; Window configurations can be undone/redone with C-c <left> / C-c <right>.
(winner-mode 1)

;; Line numbers appear in every programming buffer.
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; M-i opens a consult-imenu popup for the current buffer's structure.
;; Org headings are indexed to arbitrary depth.
(global-set-key (kbd "M-i") #'consult-imenu)
(setq org-imenu-depth 100)

;; C-c s t launches a project-wide ripgrep search.
(global-set-key (kbd "C-c r") #'consult-ripgrep)
(global-set-key (kbd "C-c s") #'rg-menu)

;; C-; opens iedit-mode, which edits all occurrences of the symbol at point.
(global-set-key (kbd "C-;") #'iedit-mode)

;; C-z opens the recent-file list instead of the default suspend-frame.
(global-set-key (kbd "C-z") #'consult-recent-file)

(require 'dired-sidebar)
(defun sidebar-toggle ()
  "Toggle both `dired-sidebar' and `ibuffer-sidebar'."
  (interactive)
  (dired-sidebar-toggle-sidebar)
  (ibuffer-sidebar-toggle-sidebar))
(global-set-key (kbd "C-x C-n") #'sidebar-toggle)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; lar — live auto-reload
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The local "lar" library is on the load path and required.
(add-to-list 'load-path (file-name-concat user-emacs-directory "elisp/lar"))
(require 'lar)

;; lar-mode is active in Org and programming buffers.
;; In programming buffers it also reloads automatically on every save.
(defun lar-auto-reload () (add-hook 'after-save-hook #'lar-reload nil t))
(add-hook 'org-mode-hook #'lar-mode)
(add-hook 'org-mode-hook #'lar-auto-reload)
(add-hook 'prog-mode-hook #'lar-mode)
(add-hook 'prog-mode-hook #'lar-auto-reload)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Interaction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Yes/no prompts accept "y" / "n" instead of the full words.
(setq use-short-answers t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Encoding
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; All text is UTF-8 with Unix line endings by default.
(set-language-environment "UTF-8")
(setq default-buffer-file-coding-system 'utf-8-unix)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Theme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The modus-vivendi-tinted dark theme is loaded at startup.
;; Bold and italic constructs are rendered as such, and mixed-pitch fonts
;; are enabled so proportional and monospaced faces coexist cleanly.
(require 'modus-themes)
(load-theme 'modus-vivendi-tinted t)
(setq modus-themes-to-toggle '(modus-operandi-tinted modus-vivendi-tinted))
(setq modus-themes-bold-constructs t
      modus-themes-italic-constructs t
      modus-themes-mixed-fonts t)

;; F5 toggles between the light and dark modus variants.
(global-set-key (kbd "<f5>") #'modus-themes-toggle)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Custom variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Customise-written variables live in custom.el, keeping init.el clean.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clipboard integration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Emacs kill-ring and system clipboard are unified: kills are available
;; for paste in other applications, and vice versa.
(setq select-enable-clipboard t
      select-enable-primary t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Font
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The default face uses JetBrains Mono at 10 pt (height 100 = 10 pt).
(set-face-attribute 'default nil
        :family "JetBrains Mono"
        :height 100)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Minibuffer completion — Vertico, Orderless, Marginalia
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Vertico provides a vertical candidate list in the minibuffer (15 rows,
;; cycling from last back to first).
(require 'vertico)
(vertico-mode 1)
(setq vertico-cycle t
      vertico-count 15)

;; Orderless matching is the primary completion style: space-separated tokens
;; match in any order, against any part of the candidate.
;; Basic and partial-completion are kept as fallbacks for files and eglot.
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles basic partial-completion))
              (eglot (styles orderless))))

;; Marginalia annotates every minibuffer candidate with contextual metadata
;; (docstrings, file sizes, key bindings, …).
(require 'marginalia)
(marginalia-mode 1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Consult — search & navigation commands
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Consult replaces several built-in commands with richer, live-preview
;; equivalents: buffer switching, bookmark jumping, yank-pop, line/imenu
;; navigation, ripgrep, and find.
(require 'consult)
(global-set-key (kbd "C-x b")   #'consult-buffer)
(global-set-key (kbd "C-x 4 b") #'consult-buffer-other-window)
(global-set-key (kbd "C-x r b") #'consult-bookmark)
(global-set-key (kbd "M-y")     #'consult-yank-pop)
(global-set-key (kbd "C-y") #'consult-yank-replace)
(global-set-key (kbd "C-s") #'consult-line)
(global-set-key (kbd "M-g g")   #'consult-goto-line)
(global-set-key (kbd "M-g M-g") #'consult-goto-line)
(global-set-key (kbd "M-g i")   #'consult-imenu)
(global-set-key (kbd "M-g I")   #'consult-imenu-multi)
(global-set-key (kbd "M-s l")   #'consult-line)
(global-set-key (kbd "M-s L")   #'consult-line-multi)
(global-set-key (kbd "M-s r")   #'consult-ripgrep)
(global-set-key (kbd "M-s f")   #'consult-find)
(global-set-key (kbd "C-c h")   #'consult-history)

;; xref (go-to-definition / find-references) uses consult for display.
(setq xref-show-xrefs-function       #'consult-xref
      xref-show-definitions-function #'consult-xref)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Embark — act on minibuffer candidates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Embark lets you act on any candidate in the minibuffer or at point
;; (open, copy, delete, …) via a contextual action menu.
;; C-.  → embark-act   (pick an action)
(require 'embark)
(require 'embark-consult)
(global-set-key (kbd "C-.")   #'embark-act)
; (global-set-key (kbd "C-;")   #'embark-dwim)
; (global-set-key (kbd "C-h B") #'embark-bindings)

;; Consult live-preview is active in embark-collect buffers.
(add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Corfu — in-buffer completion popup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Corfu shows an in-buffer popup of completion candidates.
;; corfu-terminal replaces the default child-frame renderer with a TUI-safe
;; popon popup, activated only when Emacs is not running in a GUI.
(require 'corfu)
(require 'corfu-terminal)
(unless (display-graphic-p)
  (corfu-terminal-mode 1))

;; Completion triggers automatically after 2 characters with a 200 ms delay.
;; Exact single-match candidates are not committed automatically.
(setq corfu-cycle t
      corfu-auto t
      corfu-auto-delay 0.5
      corfu-auto-prefix 2
      corfu-on-exact-match nil
      corfu-quit-no-match 'separator
      corfu-preview-current nil)

(global-corfu-mode 1)

;; corfu-history ranks previously selected candidates higher across sessions.
(require 'corfu-history)
(corfu-history-mode 1)
(add-to-list 'savehist-additional-variables 'corfu-history)
(savehist-mode 1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Cape — additional completion-at-point sources
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Cape feeds dabbrev (dynamic abbreviation), file paths, and language
;; keywords into corfu as extra completion sources.
(require 'cape)
(add-hook 'completion-at-point-functions #'cape-dabbrev)
(add-hook 'completion-at-point-functions #'cape-file)
(add-hook 'completion-at-point-functions #'cape-keyword)

;; pcomplete (used in shell/comint buffers) is wrapped so it behaves as a
;; non-exclusive capf; eglot's capf is wrapped with a cache-buster so
;; results stay fresh after edits.
(advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
(advice-add #'eglot-completion-at-point  :around #'cape-wrap-buster)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Dired
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Dired lists files in long format with human-readable sizes, directories
;; first. When two Dired buffers are open, operations default to the other
;; window as the target. Buffers auto-revert, and opening a subdirectory
;; reuses the current Dired buffer rather than spawning a new one.
(setq dired-listing-switches "-alh"
      dired-dwim-target t
      dired-auto-revert-buffer t
      dired-kill-when-opening-new-dired-buffer t)

;; Details (permissions, size, date) are hidden by default for a cleaner view.
(add-hook 'dired-mode-hook #'dired-hide-details-mode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Eldoc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Eldoc documentation is always single-line (no multi-line echo area),
;; and appears after a 200 ms idle delay.
(setq eldoc-echo-area-use-multiline-p nil
      eldoc-idle-delay 0.5)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Flymake
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Flymake checks for errors 500 ms after the last change.
;; M-n / M-p jump to the next / previous diagnostic in the buffer.
(setq flymake-no-changes-timeout 0.5)
(add-hook 'flymake-mode-hook
    (lambda ()
      (local-set-key (kbd "M-n") #'flymake-goto-next-error)
      (local-set-key (kbd "M-p") #'flymake-goto-prev-error)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Isearch
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Isearch shows a "(current/total)" match counter in the prompt,
;; and wraps around without pausing or beeping.
(setq isearch-lazy-count t
      lazy-count-prefix-format "(%s/%s) "
      isearch-wrap-pause 'no-ding)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Ibuffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; C-x C-b opens ibuffer (grouped, sortable buffer list) instead of the
;; default buffer-list.
(global-set-key (kbd "C-x C-b") #'ibuffer)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Electric pair (non-Lisp modes only)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; In programming modes that are not Lisp dialects, electric-pair-local-mode
;; auto-closes brackets, quotes, etc.  Lisp modes are excluded because
;; paredit (loaded later) handles structural editing there.
(add-hook 'prog-mode-hook
    (lambda ()
      (unless (derived-mode-p 'lisp-mode 'scheme-mode 'emacs-lisp-mode)
        (electric-pair-local-mode 1))))

(add-hook 'text-mode-hook #'electric-pair-mode)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Eglot — LSP client
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Eglot is the LSP client. The buffer is formatted automatically on save
;; while Eglot manages it.  The event log is disabled (size 0) to avoid
;; memory growth, and servers are shut down when their last buffer is closed.
(require 'eglot)
(add-hook 'eglot-managed-mode-hook
    (lambda ()
      (add-hook 'before-save-hook #'eglot-format-buffer nil t)))
(setq eglot-events-buffer-size 0
      eglot-autoshutdown t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Tree-sitter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Tree-sitter font-lock is set to level 4 (maximum granularity).
(setq treesit-font-lock-level 4)

;; Built-in language modes are remapped to their tree-sitter equivalents,
;; so opening any of these file types activates the ts variant automatically.
(setq major-mode-remap-alist
      '((python-mode     . python-ts-mode)
  (js-mode         . js-ts-mode)
  (typescript-mode . typescript-ts-mode)
  (c-mode          . c-ts-mode)
  (c++-mode        . c++-ts-mode)
  (rust-mode       . rust-ts-mode)
  (bash-mode       . bash-ts-mode)
  (css-mode        . css-ts-mode)
  (json-mode       . json-ts-mode)
  (yaml-mode       . yaml-ts-mode)
  (toml-mode       . toml-ts-mode)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Git — Magit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Magit is the Git interface. C-x g opens magit-status.
;; All hunks are shown with word-level diff refinement.
(require 'magit)
(defun transient-prefix-object ()
  (or transient--prefix transient-current-prefix))
(setq magit-diff-refine-hunk 'all)
(global-set-key (kbd "C-x g") #'magit-status)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Lisp / Scheme / Guile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Bug-reference mode turns issue numbers (e.g. #1234) into clickable links
;; in programming and ERC buffers.
(require 'bug-reference)
(add-hook 'prog-mode-hook #'bug-reference-prog-mode)
(add-hook 'erc-mode-hook  #'bug-reference-mode)

;; Matching parentheses are highlighted immediately, using a mixed style
;; (highlight the expression when the cursor is on an inner paren, or just
;; the matching paren when on the outer one).
(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-style 'mixed)

;; Paredit enforces structural S-expression editing in all Lisp modes:
;; parentheses are always balanced; slurp/barf/splice replace raw deletion.
(require 'paredit)
(add-hook 'lisp-mode-hook       #'enable-paredit-mode)
(add-hook 'scheme-mode-hook     #'enable-paredit-mode)
(add-hook 'emacs-lisp-mode-hook #'enable-paredit-mode)

;; Geiser provides an interactive Guile REPL and evaluation commands.
;; GNU Guile is the sole active implementation; .scm files open in scheme-mode.
(require 'geiser)
(setq geiser-default-implementation 'guile
      geiser-active-implementations '(guile)
      geiser-implementations-alist   '(((regexp "\\.scm$") guile)))
(require 'geiser-guile)
(setq lisp-indent-offset 2)
(add-to-list 'auto-mode-alist '("\\.scm\\'" . scheme-mode))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Org-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; org-mode is loaded explicitly so all subsequent setq forms affect the
;; real org variables rather than auto-load stubs.
(require 'org)


;;; --- Outline appearance --------------------------------------------------

(setq org-startup-indented nil)

;; Every file opens fully expanded by default.
(setq org-startup-folded nil)

;; Only the last star of a heading is shown; the others are hidden, reducing
;; visual noise while preserving the real outline structure.
(setq org-hide-leading-stars t)

;; A blank line between list items or headings is not introduced on cycling.
(setq org-cycle-separator-lines 0)

;; Ellipsis after a folded heading is rendered as a single horizontal ellipsis
;; character rather than the default "...".
(setq org-ellipsis " ⋯")


;;; --- Editing behaviour ---------------------------------------------------

;; Return key follows links (no need for C-c C-o on [[...]] links).
(setq org-return-follows-link t)

;; Hitting Return at the end of a list item creates a new item at the same
;; level; hitting it on an empty item exits the list.
(setq org-list-use-circular-motion nil)

;; Footnote definitions are placed immediately below the paragraph that
;; references them, not at the end of the file.
(setq org-footnote-section nil)


(setq org-hide-emphasis-markers t)

;; Structural template expansion (e.g. <s TAB → #+begin_src … #+end_src)
;; is enabled via org-tempo.
(require 'org-tempo)

;; Source blocks are indented by 2 spaces relative to the #+begin_src line,
;; matching the global tab-width.
(setq org-edit-src-content-indentation 2)

;; C-c ' opens a source block in its native major mode in a separate window.
;; The window is split horizontally (side by side) rather than vertically.
(setq org-src-window-setup 'split-window-right)

;; The language of a source block is fontified inside the Org buffer itself,
;; so Python looks like Python, Scheme looks like Scheme, etc.
(setq org-src-fontify-natively t)

;; Tab in a source block uses the indentation rules of the block's language,
;; not Org's own rules.
(setq org-src-tab-acts-natively t)

;; The trailing newline that Org inserts when editing a block is preserved,
;; keeping diffs clean.
(setq org-src-preserve-indentation nil)


;;; --- Babel — code execution ----------------------------------------------

;; The languages below are loaded into Babel so their blocks can be evaluated
;; with C-c C-c.  Add or remove entries as needed.
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (scheme     . t)
   (python     . t)
   (shell      . t)
   (sql        . t)))

;; Babel asks for confirmation before executing any source block, preventing
;; accidental evaluation of destructive code.
(setq org-confirm-babel-evaluate t)

;; Results of evaluated blocks are inserted inline, immediately below the
;; block, as a #+RESULTS: section.
(setq org-babel-results-keyword "RESULTS")

;; Scheme blocks are evaluated via Geiser (already configured above),
;; so the active Guile REPL is reused rather than a subprocess being spawned.
(setq org-babel-scheme-implementation 'geiser)


;;; --- Display of results --------------------------------------------------

;; Inline images are shown automatically after a block produces one.
(setq org-startup-with-inline-images t)
(add-hook 'org-babel-after-execute-hook #'org-display-inline-images)

;; LaTeX fragments ($ … $ and \[ … \]) are rendered as images on startup.
(setq org-startup-with-latex-preview nil) ; set to t if latex is available


;;; --- Navigation keybindings ----------------------------------------------

;; C-c C-j opens org-goto, a fast heading navigator for the current buffer.
;; (consult-imenu bound to M-i above already covers the same need via
;; completion; org-goto provides the built-in tree-browser alternative.)
(global-set-key (kbd "C-c o j") #'org-goto)

;; C-c o n / C-c o p jump to the next / previous heading at any level.
(global-set-key (kbd "C-c o n") #'org-next-visible-heading)
(global-set-key (kbd "C-c o p") #'org-previous-visible-heading)

(setq org-todo-keywords
      '((sequence "TODO(t)" "READY(r)" "WAITING(w)" "DOING(o)" "REMOVE(m)" "|" "DONE(d)" "FAILED(f)" "CANCELED(c)")
  (type "PUBLIC(p)")))

(setq org-todo-keyword-faces
      '(("TODO"     . (:foreground "red"     :weight bold))
  ("READY"    . (:foreground "red"     :weight bold))
  ("REMOVE"   . (:foreground "red"     :weight bold))
  ("PLANNED"  . (:foreground "red"     :weight bold))
  ("WAITING"  . (:foreground "orange"  :weight bold))
  ("DOING"    . (:foreground "orange"  :weight bold))
  ("FAILED"   . (:foreground "gray"    :weight bold))
  ("DONE"     . (:foreground "green"   :weight bold))
  ("PUBLIC"   . (:foreground "green"   :weight bold))
  ("CANCELED" . (:foreground "gray60"  :weight bold))))

(define-key org-mode-map (kbd "C-c C-l") #'org-insert-link)
(global-set-key (kbd "C-c l") #'org-store-link)
(setq org-id-link-to-org-use-id t)
(setq org-src-preserve-indentation t)
(setq org-link-keep-stored-after-insertion t)
(setq org-src-fontify-natively t)
(setq org-fontify-emphasized-text t)

;;;;;;;;;;;;;;
;; Snippets ;;
;;;;;;;;;;;;;;

(require 'f)
(require 'yasnippet)
(setq yas--default-user-snippets-dir nil)
(add-to-list 'yas-snippet-dirs (f-join user-emacs-directory "snippets"))
(setq yas-new-snippet-default
      "# -*- mode: snippet -*-
# name: $1
# key: ${2:${1:$(yas--key-from-desc yas-text)}}
# expand-env: ((yas-indent-line 'fixed) (yas-wrap-around-region 'nil))
# --
$0`(yas-escape-text yas-selected-text)`")
(yas-global-mode)


(setq enable-recursive-minibuffers t)

;;;;;;;;;;
;; Tabs ;;
;;;;;;;;;;

(require 'tab-bar)
(tab-bar-mode)
(global-set-key (kbd "C-t") #'tab-new)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; On startup, take half of the screensize ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq frame-resize-pixelwise t)
(defun my-frame-to-half-width (&optional right)
  "Resize the selected frame to exactly half the usable width of its current monitor.
With prefix argument (C-u), place it on the right half; otherwise left half.
Height is set to the full usable monitor height."
  (interactive "P")
  (let* ((workarea (frame-monitor-workarea))   ; (x y w h) usable pixels
         (x (nth 0 workarea))
         (y (nth 1 workarea))
         (w (nth 2 workarea))
         (h (nth 3 workarea))
         (half-w (floor (/ w 2)))
         (target-x (if right (+ x half-w) x)))
    (set-frame-position (selected-frame) target-x y)
    (set-frame-size (selected-frame) half-w h t)))  ; t = pixelwise
(my-frame-to-half-width)

;;;;;;;;;;;;;;;;;;
;; LSP for Bash ;;
;;;;;;;;;;;;;;;;;;

(add-to-list 'eglot-server-programs
  '((sh-mode bash-ts-mode) . ("bash-language-server" "start")))
(add-hook 'sh-mode-hook #'eglot-ensure)
