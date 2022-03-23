;;; undo-hl.el --- Highlight undo/redo  -*- lexical-binding: t; -*-

;; Author: Yuan Fu <casouri@gmail.com>
;; URL: https://github.com/casouri/undo-hl
;; Version: 1.0
;; Keywords: undo
;; Package-Requires: ((emacs "26.0"))

;;; This file is NOT part of GNU Emacs

;;; Commentary:
;;
;; Sometimes in a long undo chain where Emacs jumps to a position, I
;; can’t tell whether the undo operation just moved to this position
;; or it has also deleted some text. This package is meant to
;; alleviate that confusion: it flashes the to-be-deleted text before
;; deleting so I know what is happening.
;;
;; This package is pretty efficient, I can hold down undo button and
;; the highlight doesn’t slow down the operation.
;;

;;; Code:
;;
;; I tried to use pulse.el but it wasn’t fast enough (eg, when holding
;; down C-.), so I used a more economical implementation. Instead of a
;; flash, the highlight will persist until the next command.

(defgroup undo-hl nil
  "Custom group for undo-hl."
  :group 'undo)

(defface undo-hl-delete '((t . (:inherit diff-refine-removed)))
  "Face used for highlighting the deleted text.")

(defface undo-hl-insert '((t . (:inherit diff-refine-added)))
  "Face used for highlighting the inserted text.")

(defcustom undo-hl-undo-commands '(undo undo-only undo-redo)
  "Commands in this list are considered undo commands.
Undo-hl only run before and after undo commands."
  :type '(list function))

(defvar-local undo-hl--overlay nil
  "The overlay used for highlighting inserted region.")

(defun undo-hl--after-change (beg end len)
  "Highlight the inserted region after an undo.
This is to be called from ‘after-change-functions’, see its doc
for BEG, END and LEN."
  (when (and (memq this-command undo-hl-undo-commands)
             (eq len 0))
    ;; Flash the inserted region with insert face.
    (if undo-hl--overlay
        (move-overlay undo-hl--overlay beg end)
      (setq undo-hl--overlay (make-overlay beg end))
      (overlay-put undo-hl--overlay 'face 'undo-hl-insert))))

(defun undo-hl--before-change (beg end)
  "Highlight the to-be-deleted region before an undo.
This is to be called from ‘before-change-functions’, see its doc
for BEG and END."
  (when (and (memq this-command undo-hl-undo-commands)
             (not (eq beg end)))
    ;; Flash the to-be-deleted region with delete face.
    ;; ‘pulse-momentary-highlight-region’ is a bit too slow, so we
    ;; simply add text-property.
    (put-text-property beg end 'face 'undo-hl-delete)
    ;; Sit-for automatically redisplays.
    (sit-for 0.1)))

(defun undo-hl--cleanup ()
  "Clean up highlight."
  (when (and (not (memq this-command undo-hl-undo-commands))
             undo-hl--overlay)
    (delete-overlay undo-hl--overlay)
    (setq undo-hl--overlay nil)))

(define-minor-mode undo-hl-mode
  "Highlight undo. Note that this is a local minor mode.
I recommend only enabling this for text-editing modes."
  :lighter "UH "
  :group 'undo
  (if undo-hl-mode
      (progn
        (add-hook 'before-change-functions #'undo-hl--before-change 0 t)
        (add-hook 'after-change-functions #'undo-hl--after-change 0 t)
        (add-hook 'pre-command-hook #'undo-hl--cleanup 0 t))
    (remove-hook 'before-change-functions #'undo-hl--before-change t)
    (remove-hook 'after-change-functions #'undo-hl--after-change t)
    (remove-hook 'pre-command-hook #'undo-hl--cleanup t)))

(provide 'undo-hl)

;;; undo-hl.el ends here
