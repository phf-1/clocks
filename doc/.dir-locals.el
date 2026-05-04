((org-mode
  (fill-column . 85)
  (org-confirm-babel-evaluate . nil)
  (eval . (add-hook 'before-save-hook #'whitespace-cleanup nil t))
  (eval . (add-hook 'after-save-hook #'lar-reload nil t))))
