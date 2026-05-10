(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file 'noerror)

(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/"))
      package-archive-priorities '(("gnu" . 10)
                                   ("nongnu" . 5)
                                   ("melpa" . 0)))
(package-initialize)

(require 'use-package)
(setq use-package-always-defer t)

(let ((backup-dir (locate-user-emacs-file "backups/"))
      (auto-save-dir (locate-user-emacs-file "auto-save/")))
  (make-directory backup-dir t)
  (make-directory auto-save-dir t)
  (setq backup-directory-alist `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,auto-save-dir t))
        create-lockfiles nil))

(setq use-short-answers t
      ring-bell-function #'ignore
      sentence-end-double-space nil
      scroll-conservatively 101
      scroll-margin 0
      mouse-wheel-progressive-speed nil
      mouse-wheel-follow-mouse t
      confirm-kill-emacs nil
      confirm-kill-processes nil
      kill-emacs-query-functions nil
      evil-want-integration t
      evil-want-keybinding nil
      evil-undo-system 'undo-redo)

(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)

(defun my/save-buffers-kill-terminal-no-prompt (&optional _arg)
  (interactive "P")
  (save-buffers-kill-terminal t))

(global-set-key (kbd "C-x C-c") #'my/save-buffers-kill-terminal-no-prompt)

(use-package ultra-scroll
  :ensure t
  :demand t
  :config
  (ultra-scroll-mode 1))

(use-package evil
  :ensure t
  :demand t
  :config
  (evil-mode 1))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

(use-package gruvbox-theme
  :ensure t
  :demand t
  :config
  (load-theme 'gruvbox-dark-medium t))
