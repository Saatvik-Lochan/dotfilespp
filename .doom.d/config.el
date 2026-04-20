
;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; (map! :leader "i n" org-noter)
(setq doom-font (font-spec :family "JetBrains Mono" :size 18))
(setq doom-theme 'doom-gruvbox)

(map! :nvo "H" 'evil-first-non-blank)
(map! :nvo "L" 'evil-end-of-line)

(with-eval-after-load 'company (define-key company-active-map (kbd "C-s") nil))
(map! :i "C-s" 'evil-normal-state)
(map! :o "C-s" 'evil-normal-state)
(map! :n "C-s" 'evil-force-normal-state)

(defun evil-org-latex-preview ()
  "A hack to run org-latex-preview in normal mode."
  (interactive)
  (evil-insert 1)
  (org-latex-preview)
  (evil-normal-state)
  (evil-forward-char 1))

(after! 'org
  '(defun org-latex-preview (evil-org-latex-preview)))

;; (add-hook 'org-mode-hook 'org-fragtog-mode)

(map! :n "+" 'evil-org-latex-preview)
(map! :n "-" 'dired-jump)
(setq-default dired-kill-when-opening-new-dired-buffer t)

(map! :n "C-h" 'org-up-element)
(map! :n "C-k" 'org-backward-element)
(map! :n "C-j" 'org-forward-element)
(map! :n "C-l" 'org-down-element)

(map! :leader :g "t h" '+tmux/cd-to-here)
(map! :leader :g "t p" '+tmux/cd-to-project)

(map! :leader :g "o n" 'org-noter)
(map! :leader :g "i n" 'org-noter-insert-note)

(map! :leader :n "c X" 'flycheck-explain-error-at-point)

(setq-default projectile-project-search-path '("~/Documents/studies/comp_const"))

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;

;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; org mode hooks
;; (add-hook 'org-mode-hook 'org-fragtog-mode)
(add-hook 'org-mode-hook 'auto-fill-mode)

;; better defaults
(setq-default
 delete-by-moving-to-trash t
 window-combination-resize t
 x-stretch-cursor t
 org-noter-always-create-frame nil)

(setq
 auto-save-default t
 truncate-string-ellipsis "…"
 scroll-margin 3)

;; change the word to include the underscore
(global-superword-mode t)
(with-eval-after-load 'evil
  (defalias #'forward-evil-word #'forward-evil-symbol)
  ;; make evil-search-word look for symbol rather than word boundaries
  (setq-default evil-symbol-word-search t))

;; make custom file do stuff
;; (setq-default custom-file (expand-file-name ".custom.el" doom-user-dir))
;; (when (file-exists-p custom-file)
;;   (load custom-file))

;; set up org download
(require 'org-download)
(setq-default org-download-method 'directory)
(setq-default org-download-heading-lvl nil)
(setq-default org-download-image-dir "./.img")
(setq-default org-download-link-format "[[./.img/%s]]\n")

(with-eval-after-load "smartparens" '(sp-pair "\[", "\]"))

(defun org-insert-current-zathura ()
  "Inserts the current zathura page as a link"
  (interactive)
  (let ((file (shell-command-to-string "/home/saatvikl/.config/sway/scripts/pdf-filename.sh select")))
    (if (string-empty-p file)
        (message "There are no pdfs open in zathura")
      (insert (format "[[zathura:%s][%s]]" file (read-string "link name: " file))))))

(map! :leader :desc "insert zathura pdf page" :n "iz" #'org-insert-current-zathura)

(org-link-set-parameters "zathura"
                         :follow #'org-zathura-open)

(defun org-zathura-open (path _)
  "Visit the file at PATH"
  (call-process-shell-command (concat "/home/saatvikl/.config/sway/scripts/zathura-pageno.sh " path "&") nil 0))

;; (eval-after-load "org"
;;   '(progn
;;      (set-face-background 'org-block nil)
;;      (plist-put! org-format-latex-options :background "Transparent" :scale 2 :foreground 'auto)))

(defun fix-previous-error ()
  (interactive)
  (+spell/previous-error)
  (+spell/correct))

(defun fix-next-error ()
  (interactive)
  (+spell/next-error)
  (+spell/correct))

;; (map! :leader :n "e n" #'fix-next-error)
(map! :leader :n "e" #'org-latex-export-to-pdf)

(add-hook 'darkroom-mode-hook #'display-line-numbers-mode)

;; (add-hook 'org-mode-hook #'vi-tilde-fringe-mode)

(map! :leader :n "t d" #'darkroom-mode)
(map! :leader :n "t L" #'display-line-numbers-mode)

(setq org-latex-listings 'minted)
(setq org-latex-compiler "xelatex")
(setq org-latex-packages-alist '(("outputdir=./build" "minted" nil)))
(setq org-latex-pdf-process '("mkdir -p build"
                              "latexmk -f -pdf -xelatex -shell-escape -interaction=nonstopmode -output-directory=%o/build %f"
                              "mv %o/build/%b.pdf %O"))

(setq org-export-allow-bind-keyword t)
(setq org-latex-special-block-alist
      '((aside    "\\begin{asidebox}" "\\end{asidebox}" nil)
        (solution "\\begin{solution}" "\\end{solution}" nil)
        (sources  "\\begin{Sources}"  "\\end{Sources}"  nil)))

(setq org-cite-export-processors
      '((latex biblatex)
        (t csl)))

(use-package! citar
  :after org
  :custom
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar))

;; Transparent Background
;; (set-frame-parameter nil 'alpha-background 80)
;; (add-to-list 'default-frame-alist '(alpha-background . 80))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((perl . t)
   (shell . t)
   ;; add other languages here if needed
   ))

(setq company-idle-delay nil)
(global-display-line-numbers-mode 0)
