;;; 
;;; Commentary:
;;; Code:

;(add-to-list 'default-frame-alist '(fullscreen . maximized))

(eval-and-compile
  (when (or load-file-name byte-compile-current-file)
    (setq user-emacs-directory
          (expand-file-name
           (file-name-directory (or load-file-name byte-compile-current-file))))))

;; Initialize package manager for compile time
(eval-and-compile
  (customize-set-variable
   'package-archives '(("org"   . "https://orgmode.org/elpa/")
                       ("melpa" . "https://melpa.org/packages/")
                       ("gnu"   . "https://elpa.gnu.org/packages/")))
  (package-initialize)
  (unless (package-installed-p 'leaf)
    (package-refresh-contents)
    (package-install 'leaf))

  ;; Leaf keywords
  (leaf leaf-keywords
    :doc "Use leaf as a package manager"
    :url "https://github.com/conao3/leaf.el"
    :ensure t
    :init
    (leaf el-get
      :ensure t
      :custom
      (el-get-notify-type       . 'message)
      (el-get-git-shallow-clone . t))
    (leaf hydra :ensure t)
    :config
    (leaf-keywords-init)))

;; Compile
(eval-and-compile
  (leaf *byte-compile
    :custom
    (byte-compile-warnings . '(not free-vars))
    (debug-on-error        . nil)))
(leaf *native-compile
  :doc "Native Compile by gccemacs"
  :url "https://www.emacswiki.org/emacs/GccEmacs"
  :if (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  :custom
  (comp-deferred-compilation . nil)
  (comp-speed                . 5)
  (comp-num-cpus             . 4)
  :config
  ;(native-compile-async "~/.emacs.d/early-init.el" 4 t)
  (native-compile-async "~/.emacs.d/init.el" 4 t)
  (native-compile-async "~/.emacs.d/elpa/" 4 t)
  (native-compile-async "~/.emacs.d/el-get/" 4 t))

;; -----------------------------------------------------------------------------------------
;;
;; Generic Configurations
;;
;; -----------------------------------------------------------------------------------------

;; (window-divider-mode -1)
;; (setq window-divider-default-right-width 5)
;; (custom-set-faces
;;  '(window-divider ((t (:foreground "#2A2A2A")))))
(scroll-bar-mode -1)
(menu-bar-mode 1)
(tool-bar-mode -1)
(setq-default truncate-lines nil)

(setq backup-directory-alist '(("." . "~/.emacs.d/backup/")))

;; Silencer
(leaf no-littering
  :doc "Keep .emacs.d clean"
  :url "https://github.com/emacscollective/no-littering"
  :ensure t
  :require t
  :config
  (setq custom-file (expand-file-name "custom.el" user-emacs-directory)))
(leaf *to-be-quiet
  :doc "Quite annoying messages"
  :preface
  (defun display-startup-echo-area-message ()
    "no startup message"
    (message ""))
  :config
  (defalias 'yes-or-no-p #'y-or-n-p))

(leaf *encoding
  :doc "It's time to use UTF-8"
  :config
  (set-locale-environment "en_US.UTF-8")
  (prefer-coding-system          'utf-8-unix)
  (set-default-coding-systems    'utf-8-unix)
  (set-selection-coding-system   'utf-8-unix)
  (set-buffer-file-coding-system 'utf-8-unix))

(leaf *formatting
  :doc "text formatting. indent tab is flase"
  :custom
  (truncate-lines        . t)
  (require-final-newline . t)
  (tab-width             . 2)
  (indent-tabs-mode      . nil))

(leaf *autorevert
  :doc "Revert changes if local file is updated"
  :global-minor-mode global-auto-revert-mode
  :custom (auto-revert-interval . 0.1))

(leaf *recovery
  :doc "Save cursor place on file"
  :global-minor-mode save-place-mode)

(leaf tramp
  :doc "Edit remote file via SSH or SCP"
  :custom
  (tramp-chunksize           . 4096)
  (tramp-persistency-file-name . t)
  :config
  (customize-set-variable 'tramp-default-method "ssh")
  (with-eval-after-load 'tramp
    (add-to-list 'tramp-remote-path 'tramp-own-remote-path) ;; for finding remove env path
    ;(setq tramp-use-ssh-controlmaster-options nil) ;; ControlMasterの設定をTrampが自動的に変更しないようにする
    (setq tramp-persistency-file-name "~/.emacs.d/tramp-persistency.el")
    (setq tramp-remote-process-environment
      (append tramp-remote-process-environment
              '("BASH_ENV=~/.bashrc"
                "CONDA_AUTO_ACTIVATE_BASE=false")))
    )
)

(leaf *savehist
  :doc "save history of minibuffer"
  :global-minor-mode savehist-mode)

(leaf *recentf
  :doc "Record open files history"
  :global-minor-mode recentf-mode
  :custom
  (recentf-max-saved-items . 20000)
  (recentf-max-menu-items  . 20000)
  (recentf-auto-cleanup    . 'never)
  (recentf-exclude
   . '((expand-file-name package-user-dir)
       ".cache"
       "cache"
       "bookmarks"
       "recentf"
       "*.png"
       "*.jpeg"
       ".org_archive"
       "COMMIT_EDITMSG\\'")))

(leaf *large-file
  :doc "Adjust large file threshold"
  :custom
  (large-file-warning-threshold . 1000000))

;; Basic Editing Operation
(leaf *delsel
  :doc "Replace the region just by typing text, or delete just by hitting the DEL key"
  :global-minor-mode delete-selection-mode)

(leaf undo-tree
  :ensure t
  :bind
  ("C-x u" . undotree-toggle)
  ("M-/" . undo-tree-redo)
  :config
  (global-undo-tree-mode)
  (setq undo-tree-visualizer-timestamps t
        undo-tree-visualizer-diff t
        auto-save-default nil
        undo-tree-auto-save-history t
        undo-tree-history-directory-alist
        `(("." . ,(expand-file-name "undo-tree-history/" user-emacs-directory)))))


;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Completion
;; ;;
;; ;; -----------------------------------------------------------------------------------------

(leaf yasnippet
  :doc "Template system"
  :url "https://github.com/joaotavora/yasnippet"
  :ensure t
  :hook   (prog-mode-hook . yas-minor-mode)
  :custom (yas-snippet-dirs . '("~/.emacs.d/snippets"))
  ;:config (yas-reload-all)
  )

(leaf company
  :doc "Modular in-buffer completion framework"
  :url "http://company-mode.github.io/"
  :ensure t
  :hook (prog-mode-hook . company-mode)
  :bind
  ((:company-active-map
    ("C-n" . company-select-next)
    ("C-p" . company-select-previous)
    ("<tab>" . company-complete-common-or-cycle))
   (:company-search-map
    ("C-p" . company-select-previous)
    ("C-n" . company-select-next)))
  :custom
  (company-idle-delay  . 0)
  (company-echo-delay  . 0)
  (company-ignore-case . t)
  (company-selection-wrap-around . t)
  (company-minimum-prefix-length . 1)
  )

(leaf smartparens
  :ensure t
  :init
  :hook
  (prog-mode-hook . smartparens-mode)
  )

;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Tools
;; ;;
;; ;; -----------------------------------------------------------------------------------------

;; ;; Git ------------------------------------------------------------------------------------

(leaf *git-commit-mode
  :doc "Mode for git commit message editing"
  :mode "\\COMMIT_EDITMSG\\'")
(leaf git-modes
  :doc "Modes for git configuration files"
  :url "https://github.com/magit/git-modes"
  :ensure t)

(leaf magit
  :doc "Complete text-based user interface to Git"
  :url "https://magit.vc/"
  :ensure t
  :init
  (setq magit-completing-read-function 'ivy-completing-read)
  (setq magit-auto-revert-mode nil))

(leaf browse-at-remote
  :doc "Browse target page on github/bitbucket"
  :url "https://github.com/rmuslimov/browse-at-remote"
  :ensure t
  :custom
  (browse-at-remote-prefer-symbolic . nil))

;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Programming Mode
;; ;;
;; ;; -----------------------------------------------------------------------------------------
(leaf quickrun
  :doc "Run program quickly"
  :url "https://github.com/emacsorphanage/quickrun"
  :ensure t
  :require t
  :custom
  (quickrun-timeout-seconds . nil)
  )

(leaf eglot
  :ensure t
  :hook ((python-mode . eglot-ensure)
         (c++-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '((python-mode) "pylsp"))
  ;(add-to-list 'eglot-server-programs '((python-mode) "pyright"))
  (add-to-list 'eglot-server-programs '((c++-mode) "ccls"))
  ;; (custom-set-faces
  ;;  '(eglot-highlight-symbol-face ((t (:background "#3a3d4d" :weight bold)))))
  )

(leaf highlight-symbol
  :ensure t
  :init
  (add-hook 'prog-mode-hook 'highlight-symbol-mode)
  (add-hook 'text-mode-hook 'highlight-symbol-mode)
  :bind
  ("M-n" . highlight-symbol-next)
  ("M-p" . highlight-symbol-prev)
  :config
  (setq highlight-symbol-on-navigation-p t)
  (setq highlight-symbol-idle-delay 0)
  )

;; lsp-bridge 
;; (add-to-list 'load-path "~/.emacs.d/elpa/lsp-bridge")
;; (require 'lsp-bridge)
;; (global-lsp-bridge-mode)

;; Debugger
(leaf dap-mode
  :doc "Client for Debug Adapter Protocol"
  "M-x toggle-debug-on-error"
  :url "https://emacs-lsp.github.io/dap-mode/"
  :ensure t
  :custom ((dap-python-debugger . 'debugpy))
  :config
  (require 'dap-python)
  (require 'dap-hydra)
  (require 'lsp-mode)
  (require 'lsp-treemacs)
  (require 'lsp-docker)
  (setq dap-auto-configure-features '(sessions locals controls tooltip))
  )

;; Python
(leaf python
  :doc "Python development environment"
  :url "https://wiki.python.org/moin/EmacsPythonMode"
  :mode ("\\.py\\'" . python-mode)
  :hook
  (python-mode-hook . eglot-ensure)
  :bind
  (:python-mode-map
   ("C-c C-n" . quickrun)
   ("C-c C-a" . quickrun-with-arg)
   ("C-c C-o" . hack-open-browser)
   ("C-c C-d" . hack-print-output)
   ("C-c C-l" . hack-print-diff)
   ("C-c RET" . hack-test-all)
   ("C-c t"   . hack-test-one-sample)))

(leaf ein
  :doc "Emacs IPython Notebook"
  :ensure t
  :config
  (setq ein:completion-backend 'ein:use-company-backend)
  (setq ein:worksheet-enable-undo t)
  (setq ein:output-area-inlined-images t)
  )


(leaf markdown-mode
  :ensure t
  :mode (("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . gfm-mode))
  :custom ((markdown-command . "pandoc")))

(leaf yapfify
  :doc "Python formatter"
  :url "https://github.com/JorisE/yapfify"
  :ensure t
  :hook (python-mode-hook . yapf-mode))


  ;; :config
  ;; ;; LaTeX-mode での auto-fill-mode を無効にする
  ;; (add-hook 'LaTeX-mode-hook (lambda () (auto-fill-mode -1)))

  ;; ;; LatexMk を TeX-command-list に追加
  ;; (add-to-list 'TeX-command-list
  ;;              '("LatexMk"
  ;;                "latexmk -pvc %t"
  ;;                TeX-run-TeX nil t :help "Run LatexMk")))

(leaf yaml-mode
  :ensure t
  :mode ("\\.yml\\'" "\\.yaml\\'"))


;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Theme
;; ;;
;; ;; -----------------------------------------------------------------------------------------
(leaf kanagawa-theme
 :ensure t
  :config
  (load-theme 'kanagawa t))

(leaf doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height . 15)
  (doom-modeline-bar-width . 3)
  (doom-modeline-lsp . t)
  (doom-modeline-github . t)
  (doom-modeline-mu4e . t)
  (doom-modeline-env-version . t))

(leaf dashboard
  :ensure t
  :config
  (setq dashboard-banner-logo-title "Welcome to the Fight Club")
  (setq dashboard-startup-banner "~/.emacs.d/fightclub.png")
  (setq dashboard-items '((projects . 5)
                          (recents  . 5)
                          (agenda . 5)
                          (registers . 5)))
  (setq dashboard-center-content t)

  (setq dashboard-icon-type 'all-the-icons)
  (setq dashboard-display-icons-p t)     ; display icons on both GUI and terminal

  (setq dashboard-set-file-icons t)
  (setq dashboard-set-heading-icons t)

  (dashboard-setup-startup-hook) ;; bottom is needed
  )

(leaf highlight-indent-guides
  :ensure t
  :hook (prog-mode-hook . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-method . 'character)
  :config
  (set-face-foreground 'highlight-indent-guides-character-face "#5b6268")
  (set-face-foreground 'highlight-indent-guides-top-character-face "#5b6268")
  (set-face-foreground 'highlight-indent-guides-stack-character-face "#5b6268")
  )

;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Widgets
;; ;;
;; ;; -----------------------------------------------------------------------------------------

(leaf all-the-icons
  :doc "All the icons is used by NeoTree"
  :url "https://github.com/domtronn/all-the-icons.el"
  :ensure t)

(leaf dired
  :config
  (leaf all-the-icons-dired
    :ensure t
    :hook (dired-mode-hook . all-the-icons-dired-mode))
  )

(leaf treemacs
  :ensure t
  :custom
  :config
  (with-eval-after-load 'treemacs
    (require 'treemacs-all-the-icons)
    (treemacs-load-theme "all-the-icons"))
  (setq treemacs-width-is-initially-locked nil)

  (with-eval-after-load 'treemacs
    (setq treemacs-filewatch-mode t)
    (setq treemacs-git-mode t)
    (setq treemacs-collapse-dirs 3))
  )

;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Search Interface
;; ;;
;; ;; -----------------------------------------------------------------------------------------
(leaf projectile
  :doc "Project navigation and management library"
  :url "https://github.com/bbatsov/projectile"
  :ensure t
  :bind
  ("C-x C-s" . projectile-save-project-buffers)
  :config
  (setq projectile-completion-system 'ivy)
  (projectile-mode 1)
  )

;; ;; ;; Vertico --------------------------------------------------------------------------------
;; (leaf vertico
;;   :doc "Completion interface"
;;   :url "https://github.com/minad/vertico/"
;;   :global-minor-mode vertico-mode
;;   :ensure t
;;   :custom
;;   (vertico-cycle . t)
;;   (vertico-count . 18))

;; (leaf vertico-posframe
;;   :doc "Show Vertico in posframe"
;;   :url "https://github.com/tumashu/vertico-posframe"
;;   :global-minor-mode vertico-posframe-mode
;;   :ensure t
;;   :custom
;;   (vertico-posframe-border-width . 5)
;;   (vertico-posframe-parameters
;;    .  '((left-fringe . 8)
;;         (right-fringe . 8)))
;;   )

;; ;; ;; ivy --------------------------------------------------------------------------------
(leaf ivy
  :ensure t
  :custom ((ivy-use-virtual-buffers . t)
           (enable-recursive-minibuffers . t))
  :config
  (ivy-mode 1)
  (custom-set-faces
   '(ivy-minibuffer-match-face-1 ((t (:foreground "#66ff00" :background "#2E2E2E" :weight bold)))))
  )

(leaf counsel
  :ensure t
  :bind
  ("C-s" . swiper)
  ("M-s r" . ivy-resume)
  ("C-c v p" . ivy-push-view)
  ("C-c v o" . ivy-pop-view)
  ("C-c v ." . ivy-switch-view)
  ("M-s c" . counsel-ag)
  ("M-o f" . counsel-fzf)
  ("M-o r" . counsel-recentf)
  ("M-y" . counsel-yank-pop)
  :custom
  (counsel-yank-pop-height . 15)
  (enable-recursive-minibuffers . t)
  (ivy-use-selectable-prompt . t)
  (ivy-use-virtual-buffers . t)
  (swiper-action-recenter . t)
  :config
  (counsel-mode 1)
  ;; Enhance fuzzy matching
  (leaf flx
    :ensure t)
  ;; Enhance M-x
  (leaf amx
    :ensure t)

  (leaf counsel-projectile
    :ensure t
    :config (counsel-projectile-mode 1))
  )

(leaf ivy-posframe
  :ensure t
  :custom
  (ivy-display-function #'ivy-posframe-display-at-frame-center)
  ;; (ivy-posframe-width 130)
  ;; (ivy-posframe-height 11)
  (ivy-posframe-parameters
   '((left-fringe . 5)
     (right-fringe . 5)))
  :hook
  (ivy-mode . ivy-posframe-enable))

(leaf ivy-rich
  :ensure t
  :after ivy
  :custom (ivy-rich-path-style . 'abbrev)
  :config
  (ivy-rich-mode 1))

(leaf all-the-icons-ivy-rich
  :ensure t
  :after ivy-rich
  :config
  (all-the-icons-ivy-rich-mode 1))

;;;-----

(leaf consult
  :doc "Generate completion candidates and provide commands for completion"
  :url "https://github.com/minad/consult"
  :ensure t
  :bind
  ("M-y"   . consult-yank-pop)
  ("C-x b" . consult-buffer)
  :custom (consult-async-min-input . 1))
(leaf consult-flycheck
  :doc "Consult integration for Flycheck"
  :url "https://github.com/minad/consult-flycheck"
  :ensure t)
(leaf affe
  :doc "Asynchronous Fuzzy Finder"
  :url "https://github.com/minad/affe"
  :ensure t)
(leaf consult-ghq
  :doc "Consult integration for ghq (with affe)"
  :url "https://github.com/tomoya/consult-ghq"
  :ensure t)
(leaf consult-custom
  :doc "Custom functions to search org documents"
  :after affe
  :require affe)
(leaf ag
  :ensure t)

(leaf marginalia
  :doc "Explain details of the consult candidates"
  :url "https://github.com/minad/marginalia"
  :global-minor-mode marginalia-mode
  :ensure t
  :custom-face
  (marginalia-documentation . '((t (:foreground "#6272a4")))))

(leaf all-the-icons-completion
  :ensure t
  :after (all-the-icons marginalia)
  :init
  (all-the-icons-completion-mode))

(leaf orderless
  :doc "Completion style that matches multiple regexps"
  :url "https://github.com/oantolin/orderless"
  :ensure t
  :preface
  (defun flex-if-apostrophe (pattern _index _total)
    (when (string-suffix-p "'" pattern)
      `(orderless-flex . ,(substring pattern 0 -1))))
  (defun without-if-bang (pattern _index _total)
    (cond
     ((equal "!" pattern)
      '(orderless-literal . ""))
     ((string-prefix-p "!" pattern)
      `(orderless-without-literal . ,(substring pattern 1)))))
  :custom
  (completion-styles           . '(orderless))
  (orderless-style-dispatchers . '(flex-if-apostrophe
                                   without-if-bang)))

(leaf embark
  :doc "Mini-Buffer Actions Rooted in Keymaps Resources"
  :url "https://github.com/oantolin/embark"
  :ensure t
  :bind*
  ("M-a" . embark-act)
  :custom
  (prefix-help-command . #'embark-prefix-help-command))

(leaf embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Accessibility
;; ;;
;; ;; -----------------------------------------------------------------------------------------

;; Input Assistance
(leaf *hydra-theme
  :doc "Make emacs bindings that stick around"
  :url "https://github.com/abo-abo/hydra"
  :custom-face
  )
(leaf major-mode-hydra
  :doc "Use pretty-hydra to define template easily"
  :url "https://github.com/jerrypnz/major-mode-hydra.el"
  :ensure t
  :require pretty-hydra)
(leaf hydra-posframe
  :doc "Show hidra hints on posframe"
  :url "https://github.com/Ladicle/hydra-posframe"
  :if (window-system)
  :el-get "Ladicle/hydra-posframe"
  :global-minor-mode hydra-posframe-mode
  :custom
  (hydra-posframe-border-width . 5)
  (hydra-posframe-parameters   . '((left-fringe . 8) (right-fringe . 8)))
  :custom-face
  (hydra-posframe-border-face . '((t (:background "#323445")))))

(leaf which-key
  :doc "Displays available keybindings in popup"
  :url "https://github.com/justbur/emacs-which-key"
  :ensure t
  :global-minor-mode which-key-mode)

;; fill-column
(leaf visual-fill-column
  :doc "Centering & Wrap text visually"
  :url "https://codeberg.org/joostkremers/visual-fill-column"
  :ensure t
  :hook ((markdown-mode-hook org-mode-hook) . visual-fill-column-mode)
  :custom
  (visual-fill-column-width . 100)
  (visual-fill-column-center-text . t))

(leaf display-fill-column-indicator-mode
  :doc "Indicate maximum colum"
  :url "https://www.emacswiki.org/emacs/FillColumnIndicator"
  :hook ((markdown-mode-hook git-commit-mode-hook) . display-fill-column-indicator-mode))

(leaf display-line-numbers
  :doc "Display line number"
  :url "https://www.emacswiki.org/emacs/LineNumbers"
  :ensure t
  :hook ((prog-mode-hook . display-line-numbers-mode)
         (text-mode-hook . display-line-numbers-mode)))

(leaf rainbow-mode
  :doc "Color letter that indicate the color"
  :url "https://elpa.gnu.org/packages/rainbow-mode.html"
  :ensure t
  :hook (emacs-lisp-mode-hook . rainbow-mode))

(leaf rainbow-delimiters
  :doc "Display brackets in rainbow"
  :url "https://www.emacswiki.org/emacs/RainbowDelimiters"
  :ensure t
  :hook (prog-mode-hook . rainbow-delimiters-mode))

(leaf ace-window
  :bind (("C-x o" . ace-window))
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (custom-set-faces
 '(aw-leading-char-face
   ((t (:inherit ace-jump-face-foreground :foreground "red" :height 3.0))))))
  
;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Cursor
;; ;;
;; ;; -----------------------------------------------------------------------------------------

(leaf *general-cursor-options
  :custom
  (kill-whole-line  . t)
  (track-eol        . t)
  (line-move-visual . nil))

(leaf mwim
  :doc "Move cursor to beginning/end of code or line"
  :url "https://github.com/alezost/mwim.el"
  :ensure t
  :bind*
  (("C-a" . mwim-beginning-of-code-or-line)
   ("C-e" . mwim-end-of-code-or-line)))

;; Avy
(leaf avy
  :doc "Jump to things in tree-style"
  :url "https://github.com/abo-abo/avy"
  :ensure t)
(leaf avy-zap
  :doc "Zap to char using avy"
  :url "https://github.com/cute-jumper/avy-zap"
  :ensure t)


;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; Bookmarks
;; ;;
;; ;; -----------------------------------------------------------------------------------------
(leaf bookmark
  :ensure t
  :custom ((bookmark-default-file . "~/.emacs.d/bookmarks")
           (bookmark-save-flag . 1))
  :bind (("C-x r m" . bookmark-set)
         ("C-x r b" . bookmark-jump)))

;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; tools
;; ;;
;; ;; -----------------------------------------------------------------------------------------

(leaf pandoc
  :ensure t
  :after markdown-mode)

(leaf vterm
  ;; requirements: brew install cmake libvterm libtool
  :ensure t
  :custom
  (vterm-max-scrollback . 10000)
  (vterm-buffer-name-string . "vterm: %s")
  :config
  ;; (defun my/vterm-counsel-yank-pop-action (orig-fun &rest args)
  ;;   (if (equal major-mode 'vterm-mode)
  ;;       (let ((inhibit-read-only t)
  ;;             (yank-undo-function (lambda (_start _end) (vterm-undo))))
  ;;         (cl-letf (((symbol-function 'insert-for-yank)
  ;;                    (lambda (str) (vterm-send-string str t))))
  ;;           (apply orig-fun args)))
  ;;     (apply orig-fun args)))
  ;; (advice-add 'counsel-yank-pop-action :around #'my/vterm-counsel-yank-pop-action)
  )

;; ;; -----------------------------------------------------------------------------------------
;; ;;
;; ;; env
;; ;;
;; ;; -----------------------------------------------------------------------------------------
;; (leaf exec-path-from-shell
;;   :doc "import env variables (ちょっと起動に時間かかる)"
;;   :ensure t
;;   :init
;;   (when (memq system-type '(gnu/linux darwin))
;;     (exec-path-from-shell-initialize)))

;; (leaf evil
;;   :ensure t
;;   :config
;;   (evil-mode 1)
;;   ; insert mode for emacs bind
;;   (setcdr evil-insert-state-map nil)
;;   (define-key evil-insert-state-map [escape] 'evil-normal-state)

;;   ; treemacs
;;   (define-key evil-normal-state-map (kbd "SPC t") 'treemacs)
;;   (define-key evil-normal-state-map (kbd "SPC 0") 'treemacs-select-window)
;;   )

;; (leaf evil-collection
;;   :ensure t
;;   :init (evil-collection-init))
