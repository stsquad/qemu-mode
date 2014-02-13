;;; qemu-mode.el --- Comint based QEMU mode
;;
;; Copyright (C) 2014  Alex Bennée
;;
;; Author: Alex Bennée <alex@bennee.com>
;; Maintainer: Alex Bennée <alex@bennee.com>
;; Version: 0.1
;; Homepage: https://github.com/stsquad/qemu-mode
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; There is at least one other mode for running qemu but I couldn't
;; find it's upstream and it was over 4 years old and not in active
;; development. As I work with QEMU and use Emacs as my principle
;; development environment I thought I would have a go using the more
;; modern comint mode.
;;
;;; Code:

;; uncomment to debug
;; (setq debug-on-error t)
;; (setq edebug-all-defs t)

(require 'comint)

(defvar qemu-executable-path
  "/home/alex/lsrc/qemu.git/aarch64-softmmu/qemu-system-aarch64"
  "Path to the QEMU executable.")

(defvar qemu-kernel-image
  nil
  "Path to bootable Kernal Image.")

(defvar qemu-rootfs-image
  nil
  "Path to the rootfs for QEMU.")

(defvar qemu-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    ;; define keys
    map)
  "Basic mode map for `run-qemu'.")

(defvar qemu-prompt-regexp "^(qemu)"
    "Prompt for `run-qemu'.")

;; Functions

(defun qemu--arguments ()
  "Return the QEMU arguments."
  '("--monitor" "stdio"))

(defun run-qemu ()
  "Run an inferior instance of `qemu-cli' inside Emacs."
  (interactive)
  (let* ((qemu-program qemu-executable-path)
         (buffer (comint-check-proc "QEMU")))
    ;; pop to the "*QEMU*" buffer if the process is dead, the
    ;; buffer is missing or it's got the wrong mode.
    (pop-to-buffer-same-window
     (if (or buffer (not (derived-mode-p 'qemu-mode))
             (comint-check-proc (current-buffer)))
         (get-buffer-create (or buffer "*QEMU*"))
       (current-buffer)))
    ;; create the comint process if there is no buffer.
    (unless buffer
      (apply 'make-comint-in-buffer "QEMU" buffer
             qemu-program (qemu--arguments))
            (qemu-mode))))

;; Mode boiler plate
(defun qemu--initialize ()
  "Helper function to initialize QEMU"
  (setq comint-process-echoes t)
  (setq comint-use-prompt-regexp t))

(define-derived-mode qemu-mode comint-mode "QEMU"
    "Major mode for `run-qemu'.

\\<qemu-mode-map>"
    nil "QEMU"
    ;; this sets up the prompt so it matches things like: [foo@bar]
    (setq comint-prompt-regexp qemu-prompt-regexp)
    ;; this makes it read only; a contentious subject as some prefer the
    ;; buffer to be overwritable.
    (setq comint-prompt-read-only t)
    ;; this makes it so commands like M-{ and M-} work.
    (set (make-local-variable 'paragraph-separate) "\\'")
      (set (make-local-variable 'font-lock-defaults)
           '(qemu-font-lock-keywords t))
      (set (make-local-variable 'paragraph-start) qemu-prompt-regexp))

;; this has to be done in a hook. grumble grumble.
(add-hook 'qemu-mode-hook 'qemu--initialize)

(provide 'qemu-mode)
;;; qemu-mode.el ends here
