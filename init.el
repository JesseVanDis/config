;; http://ergoemacs.org/emacs/elisp_basics.html

;; setup:
;; cd /.emacs.d/
;; rm ./init.el
;; wget https://raw.githubusercontent.com/PrimeVest/emacsinit/master/init.el

;; to try out lisp code:
;;  - highlight the code you want to test
;;  - then 'M-x' eval-region


(setq gc-cons-threshold 64000000) (add-hook 'after-init-hook #'(lambda () (setq gc-cons-threshold 800000))) ; Hack: Faster startup times
(require 'package)                                                                     ; init: load packages only once
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")                             ; init: Add load paths (2/2)
  (add-to-list 'load-path "~/.emacs.d/loadpath/")                                      ; init:   Add load paths (2/2)
(package-initialize)                                                                   ; init: Activate all the packages (in particular autoloads)
(unless package-archive-contents (package-refresh-contents))                           ; init: Update your local package index
(setq package-archives '(("melpa-stable" . "https://stable.melpa.org/packages/")       ; init: add package archives (1/3)
                         ("melpa" . "http://melpa.milkbox.net/packages/")              ; init:   add package archives (2/3)
                         ("gnu" . "http://elpa.gnu.org/packages/")))                   ; init:   add package archives (3/3)
(setq package-enable-at-startup nil)                                                   ; init: Disable package init at startup. (will be done anyway when needed)
(setq package--init-file-ensured t)                                                    ; init: Ask package.el to not add (package-initialize) to .emacs.
(eval-and-compile                                                                      ; init: use verbose in packages (1/2)
  (setq use-package-verbose (not (bound-and-true-p byte-compile-current-file))))       ; init:   use verbose in packages (2/2)
(mapc #'(lambda (add) (add-to-list 'load-path add))                                    ; init: Package setup: Add the package.el loadpaths to load-path (1/7)
  (eval-when-compile (require 'package) (package-initialize)                           ; init:   Package setup: Add the package.el loadpaths to load-path (2/7)
  (unless (package-installed-p 'use-package)                                           ; init:   Package setup: Install use-package if not installed yet  (3/7)
  (package-refresh-contents) (package-install 'use-package))                           ; init:   Package setup: Install use-package if not installed yet  (4/7)
  (let ((package-user-dir-real (file-truename package-user-dir)))                      ; init:   Package setup: "require 'use-package"                    (5/7)
  (nreverse (apply #'nconc (mapcar #'(lambda (path)                                    ; init:   Package setup: reverse, because outside mapc             (6/7)   
  (if (string-prefix-p package-user-dir-real path) (list path) nil)) load-path))))))   ; init:   Package setup: Only keep package.el provided loadpaths.  (7/7)
(add-to-list 'load-path (expand-file-name "~/.emacs.d/plugins"))                       ; init: extra plugins and config files are stored here

; ===================== GENERATED =======================

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
	("190a9882bef28d7e944aa610aa68fe1ee34ecea6127239178c7ac848754992df" "fa2b58bb98b62c3b8cf3b6f02f058ef7827a8e497125de0254f56e373abee088" default)))
 '(inhibit-startup-screen t)
 '(package-selected-packages
   (quote
	(ergoemacs-mode evil-search-highlight-persist idle-highlight-mode flycheck-gometalinter flycheck-golangci-lint easy-escape iflipb evil-visualstar autopair paredit ac-slime company-tern xref-js2 js2-refactor js2-mode dirtree modern-cpp-font-lock flycheck-ycmd company-ycmd ycmd go-mode go-autocomplete auto-complete use-package nyan-mode helm-projectile helm-ag smooth-scroll f evil-leader))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:bold nil :foreground "#222222"))))
 '(font-lock-doc-face ((t (:foreground "CadetBlue"))))
 '(font-lock-string-face ((t (:foreground "chocolate"))))
 '(font-lock-warning-face ((t (:foreground "DarkRed")))))

; =======================================================

(require 'spacemacs-light-theme) (load-theme 'spacemacs-light)                         ; theme: spacemacs-light

(defvar keycomb-c-s-tab                                                                ; var: key combination of Ctrl+Shift+Tab (1/2)
  (if (featurep 'xemacs) (kbd "<C-iso-left-tab>") (kbd "<C-S-iso-lefttab>")))          ; var:   key combination of Ctrl+Shift+Tab (2/2)

(setq backup-directory-alist `(("." . "~/.saves")))                                    ; setting: put backup files in another dir (1/2)
  (setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups"))))    ; setting:   put backup files in another dir (2/2)
(setq create-lockfiles nil)                                                            ; setting: stop creating lock files
(setq make-backup-files nil)                                                           ; setting: stop creating backup~ files
(setq auto-save-default nil)                                                           ; setting; stop creating #autosave# files
(show-paren-mode 1)                                                                    ; setting: highlight other end of bracket
(set-default 'truncate-lines t)                                                        ; setting: disable linewrap
(tool-bar-mode 0)                                                                      ; setting: Disable toolbar
(if (fboundp #'save-place-mode) (save-place-mode +1) (setq-default save-place t))      ; setting: save last cursor position
(setq-default cursor-type 'bar)                                                        ; setting: make the cursor a bar
(setq ns-use-mwheel-momentum nil)                                                      ; setting: fix scrolling (1/5)
  (setq scroll-margin 0 scroll-conservatively 100000 scroll-preserve-screen-position 1); setting:   fix scrolling (2/5)
  (setq mouse-wheel-scroll-amount '(3 ((shift) . 1)))                                  ; setting:   fix scrolling (3/5): one line at a time
  (setq scroll-step 1)                                                                 ; setting:   fix scrolling (4/5): still one line at a time
  (setq mouse-wheel-progressive-speed nil)                                             ; setting:   fix scrolling (5/5): don't accelerate scrolling
  (setq mouse-wheel-follow-mouse 't)                                                   ; setting: scroll window under mouse
(savehist-mode 1)                                                                      ; setting: save M-x history  ( the command history... )
(global-undo-tree-mode)                                                                ; setting: save undo history (1/3)
  (setq undo-tree-auto-save-history t)                                                 ; setting:   save undo history (2/3)
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))                ; setting:   save undo history (3/3)
;;(horizontal-scroll-bar-mode 1)                                                       ; setting: horizontal scrollbar
(setq-default tab-width 4) (setq js-indent-level 4)                                    ; setting: set tab spacing to 4 spaces
(global-hl-line-mode 1)                                                                ; setting: highlight line
(add-hook 'window-setup-hook 'display-line-numbers-mode)                               ; setting: add line numbers (1/2) ( hook because of below v26 bug )
  (add-hook 'menu-bar-update-hook 'display-line-numbers-mode)                          ; setting:   add line numbers (2/2)
(cua-mode 1)                                                                           ; setting: Cut/Paste with C-x, C-v
(setq initial-major-mode 'todo-list-mode)                                              ; setting: set scratch-mode to the todo-list-mode
(add-to-list 'auto-mode-alist '("\\.todo\\'" . todo-list-mode))                        ; setting: open .todo     files in TODO mode
(add-to-list 'auto-mode-alist '("\\.locatext\\'" . nxml-mode))                         ; setting: open .locatext files in XML mode
(setq x-select-enable-primary nil)                                                     ; setting: copy/paste over system clipboard (1/2)
(setq x-select-enable-clipboard t)                                                     ; setting: copy/paste over system clipboard (2/2)

(use-package f :ensure t)                                                              ; plugin: easy filename manipulation
(use-package nyan-mode :config (nyan-mode 1))                                          ; plugin: nyan cat
(use-package autopair :ensure t :config (autopair-global-mode))                        ; plugin: add '}' after typing '{'
(use-package iflipb :ensure t :config                                                  ; plugin: easy buffer swap with Ctrl+(Shift)+Tab (1/3)
  (global-set-key (kbd "<C-tab>") 'iflipb-next-buffer)                                 ; plugin:   easy buffer swap with Ctrl+(Shift)+Tab (2/3)
  (global-set-key keycomb-c-s-tab 'iflipb-previous-buffer))                            ; plugin:   easy buffer swap with Ctrl+(Shift)+Tab (3/3)
(use-package modern-cpp-font-lock :ensure t)                                           ; plugin: C++ highlighting (1/2)
  (add-hook 'c++-mode-hook #'modern-c++-font-lock-mode)                                ; plugin:   C++ highlighting (2/2)

(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)                   ; Shortcut: Esc to cancel any minibuffer (1/5)
  (define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)              ; Shortcut:   Esc to cancel any minibuffer (2/5)
  (define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)      ; Shortcut:   Esc to cancel any minibuffer (3/5)
  (define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)      ; Shortcut:   Esc to cancel any minibuffer (4/5)
  (define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)         ; Shortcut:   Esc to cancel any minibuffer (5/5)

;; HOW TO DEFINE A FONT

; group 1 is the only thing highlighted ( so everything within curcly brackets ).
; the things around it can be considered look-ahead or look-behind
; the \\< \\> means start / end of word ( seperated by space or whatever )

; M-x re-builder <RET>
; M-x font-lock-fontify-buffer   to refresh screen
; C-u C-x                        to check the face under the current cursor
; M-x helm-color <RET>           to see all color codes
; M-x describe-face              to see current font
; M-x list-faces-display         to see more info

; link: https://emacs.stackexchange.com/questions/2957/how-to-customize-syntax-highlight-for-just-a-given-mode
; link: https://emacs.stackexchange.com/questions/13128/highlighting-shell-variables-within-quotes
; link: https://emacs.stackexchange.com/questions/20748/how-to-prevent-font-lock-from-being-lazy
; link: https://stackoverflow.com/questions/1076503/change-emacs-syntax-highlighting-colors

; font examples:
(add-hook 'emacs-lisp-mode-hook (lambda () (font-lock-add-keywords nil '(
  ("\\(;; font1\\)" 1 font-lock-warning-face prepend)
  ("\\(;; font2\\)" 1 font-lock-function-name-face prepend)
  ("\\(;; font3\\)" 1 font-lock-variable-name-face prepend)
  ("\\(;; font4\\)" 1 font-lock-keyword-face prepend)
  ("\\(;; font5\\)" 1 font-lock-comment-face prepend)
  ("\\(;; font6\\)" 1 font-lock-comment-delimiter-face prepend)
  ("\\(;; font7\\)" 1 font-lock-type-face prepend)
  ("\\(;; font8\\)" 1 font-lock-constant-face prepend)
  ("\\(;; font9\\)" 1 font-lock-builtin-face prepend)
  ("\\(;; fontA\\)" 1 font-lock-preprocessor-face prepend)
  ("\\(;; fontB\\)" 1 font-lock-string-face prepend)
  ("\\(;; fontC\\)" 1 font-lock-doc-face prepend)
  ("\\(;; fontD\\)" 1 font-lock-negation-char-face prepend)
))))

; XML
(defvar  efont-xml-f1 'efont-xml-f1 "Custom font.")
(defface efont-xml-f1 '((t :inherit font-lock-constant-face :bold nil :foreground "black")) "Custom font." :group 'font-lock-faces)
(defvar  efont-xml-f2 'efont-xml-f2 "Custom font.")
(defface efont-xml-f2 '((t :inherit font-lock-function-name-face :bold nil :foreground "DarkCyan")) "Custom font." :group 'font-lock-faces)
(defvar  efont-xml-f3 'efont-xml-f3 "Custom font.")
(defface efont-xml-f3 '((t :inherit font-lock-doc-face :foreground "CadetBlue")) "Custom font." :group 'font-lock-faces)
(defvar  efont-xml-f4 'efont-xml-f4 "Custom font.")
(defface efont-xml-f4 '((t :inherit font-lock-warning-face :foreground "DarkRed")) "Custom font." :group 'font-lock-faces)

(add-hook 'nxml-mode-hook (lambda () (font-lock-add-keywords nil '(
	("\\([<]\\)" 1 efont-xml-f2 prepend)
	("\\([<][/]\\)" 1 efont-xml-f2 prepend)
	("\\([>]\\)" 1 efont-xml-f2 prepend)
	("\\([/][>]\\)" 1 efont-xml-f2 prepend)
	("\\([<]\\w*\\)" 0 efont-xml-f2 t)
	("\\([<][/]\\w*\\)" 0 efont-xml-f2 t)
	("\\([?][>]\\)" 1 font-lock-keyword-face prepend)
	("\\([<][?]\\)" 1 font-lock-keyword-face prepend)
) 'append)))

; TODO
(defvar  efont-todo-f1 'efont-todo-f1 "Custom font.")
(defface efont-todo-f1 '((t :inherit font-lock-string-face :foreground "DarkGreen" :strike-through t)) "Custom font." :group 'font-lock-faces)
(defvar  efont-todo-f2 'efont-todo-f2 "Custom font.")
(defface efont-todo-f2 '((t :inherit font-lock-string-face :foreground "grey")) "Custom font." :group 'font-lock-faces)
(defvar  efont-todo-f3 'efont-todo-f3 "Custom font.")
(defface efont-todo-f3 '((t :inherit font-lock-type-face :height 1.5 :weight: bold)) "Custom font." :group 'font-lock-faces)
(defvar  efont-todo-f4 'efont-todo-f4 "Custom font.")
(defface efont-todo-f4 '((t :inherit font-lock-comment-face)) "Custom font." :group 'font-lock-faces)

(define-derived-mode todo-list-mode fundamental-mode "todo-list" (font-lock-add-keywords nil '(
	("\\([-]\\)" 1 font-lock-keyword-face prepend)
	("\\([ ][~][ ].*\\)" 1 efont-todo-f2 prepend)
	("\\([->]\\)" 1 font-lock-keyword-face prepend)
	("\\([ ][*][ ]\\)" 1 font-lock-variable-name-face prepend)
	("\\([*].*[*]\\)" 1 font-lock-function-name-face prepend)
	("\\([=][=][=].*[=][=][=]\\)" 1 efont-todo-f3 prepend)
	("\\([#].*\\)" 1 efont-todo-f1 prepend)
	("\\([/][/].*\\)" 1 efont-todo-f4 prepend)
	("\\([;][;].*\\)" 1 efont-todo-f4 prepend)
)))


