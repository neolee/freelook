(defgroup freelook nil
  "Sample customization group for FreeLook."
  :group 'tools)

(defcustom freelook-theme 'auto
  "Preferred preview theme."
  :type '(choice (const :tag "Auto" auto)
                 (const :tag "Light" light)
                 (const :tag "Dark" dark)))

(defun freelook-preview-message (path)
  "Show a sample preview message for PATH."
  (interactive "fPreview file: ")
  (message "Previewing %s with theme %s" path freelook-theme))

(setq freelook-supported-modes '(markdown-mode json-mode emacs-lisp-mode))
