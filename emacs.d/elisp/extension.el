;;; -*- lexical-binding: t; -*-

(defun clocks-org-link-search-id-dollar (s)
  "Support search strings starting with $ to look up the :ID: property.
This enables #+INCLUDE with ::$UUID syntax (parallel to ::# for CUSTOM_ID)."
  (when (eq (string-to-char s) ?$)
    (let* ((case-fold-search t)
           (normalized (replace-regexp-in-string "\n[ \t]*" " " s))
           (id (substring normalized 1))
           (match (org-find-property "ID" id)))
      (if match
          (progn (goto-char match) t)   ; success → non-nil stops the hook
        (error "No match for ID: %s" id)))))

(add-hook 'org-execute-file-search-functions #'clocks-org-link-search-id-dollar)
