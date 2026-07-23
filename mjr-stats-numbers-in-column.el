;; mjr-stats-numbers-in-column. -*-coding: utf-8 lexical-binding:t; mode:emacs-lisp; fill-column:158 -*-

;; Copyright (c) 2026-2026 Mitch Richling <https://www.mitchr.me>.  All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
;;
;; 1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without
;;    specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
;; TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;; Author:      Mitch Richling
;; Version:     0.2
;; Keywords:    mjr-stats-numbers-in-column
;; URL:         https://github.com/richmit/mjr-stats-numbers-in-column

;; This file is not part of Emacs

;;; Install:
;; See the README: https://github.com/richmit/mjr-stats-numbers-in-column/

;;; Commentary:
;; See the README: https://github.com/richmit/mjr-stats-numbers-in-column/

;;; Code:

(require 'dired)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defgroup mjr-stats-numbers-in-column nil
  "mjr-meta-eval"
  :group 'convenience
  :group 'development)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defcustom mjr-stats-numbers-in-column-num-digits-max 5
  "Use `ido-completing-read' if non-NIL.  Otherwise use `read-answer'.
`read-answer' provides a faster, but more terse user interface -- i.e. only one keystroke to select an evaluation method instead of two."
  :type 'integer
  :group 'mjr-stats-numbers-in-column)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-stats-numbers-in-column (start end)
  "Compute statistics for numbers in a column.  Results are  put on the kill ring.

When run interactively the column of numbers is identified in one of two ways:
  * Rectangular .. With an active, rectangular region -- one number per line of the rectangle
  * Point ........ Number found under the point, and continues to subsequent lines below the current one until a line is reached with no number.
When called non-interactively the rectangle method is used when start != end, otherwise the point method is used.
The point will be moved to the end of the last number found as a visual queue to the user when the point method is used.

This function returns an alist of statistics: :sum :mean :median :min :max :sd :psd :range :n :var :pvar :sumsq
When called interactively a summary is printed and placed on the kill ring  -- see `mjr-stats-numbers-in-column-num-digits-max'."
  (interactive (if (and transient-mark-mode (region-active-p) (not (= (region-beginning) (region-end))))
                   (list (region-beginning) (region-end))
                   (list (point) (point))))
  (let* ((num-regexp  "[-+]?\\([0-9]+\\.?[0-9]*\\|\\.[0-9]+\\)\\([eE][-+]?[0-9]+\\)?")
         (datas       (if (not (= start end))
                          (mapcar (lambda (s) (substring-no-properties s)) (extract-rectangle start end))
                          (let ((seed-string-number  (and (goto-char start) (thing-at-point-looking-at num-regexp 40) (match-string 0))))
                            (if (not seed-string-number)
                                (error "mjr-stats-numbers-in-column: ERROR: Point not on number")
                                (let ((target-column   (current-column))
                                      (list-of-number-strings (list seed-string-number)))
                                  (while (let ((last-line  (line-number-at-pos))
                                               (last-point (point)))
                                           (or (when (zerop (forward-line 1))
                                                 (when (or 't (not (= last-point (point))))
                                                   (let ((line-start (point)))
                                                     (move-to-column target-column 't)
                                                     (when (and (or (zerop target-column) (not (= line-start (point))))
                                                                (= target-column (- (point) line-start)))
                                                       (let ((nap (and (thing-at-point-looking-at num-regexp 40) (match-string 0))))
                                                         (when nap
                                                           (setq list-of-number-strings (cons nap list-of-number-strings))))))))
                                               (null (goto-char last-point)))))
                                  (reverse list-of-number-strings))))))
         (data        (mapcar (lambda (s) (float (string-to-number s))) datas))
         (sig-digits  (apply #'max (mapcar (lambda (x) (length (replace-regexp-in-string "0+e.*$" "" (format "%.50e" x)))) data)))
         (sorted-data (sort (cl-copy-list data) #'<))
         (prt-digits  (min sig-digits
                           (if (and (integerp mjr-stats-numbers-in-column-num-digits-max) (< 0 mjr-stats-numbers-in-column-num-digits-max))
                               mjr-stats-numbers-in-column-num-digits-max
                               5)))
         (zero-eps    (expt 10 (- (+ 2 prt-digits))))
         (the-n       (length sorted-data))
         (the-min     (cl-first sorted-data))
         (the-sum     (apply '+ sorted-data))
         (the-mean    (if (< 0 the-n) (/ (* 1.0 the-sum) the-n)))
         (the-median  (if (cl-evenp the-n) (/ (+  (nth (/ (- the-n 1) 2) sorted-data) (nth (/ the-n 2) sorted-data)) 2.0) (nth (/ the-n 2) sorted-data)))
         (the-sumsq   (apply '+ (mapcar (lambda (x) (* x x)) sorted-data)))
         (the-var     (if (< 0 the-n) (- (/ the-sumsq the-n) (* the-mean the-mean))))
         (the-pvar    (if (< 1 the-n) (/ (* the-var the-n) (- the-n 1))))
         (the-sd      (if (and the-var (< 0 the-var)) (sqrt the-var)))
         (the-psd     (if (and the-pvar (< 0 the-pvar)) (sqrt the-pvar)))
         (the-max     (car (last sorted-data)))
         (the-range   (- the-max the-min))
         (stat-alist  (list (cons :sum the-sum) (cons :mean the-mean) (cons :median the-median) (cons :min   the-min)
                            (cons :max the-max) (cons :sd   the-sd)   (cons :psd    the-psd)    (cons :range the-range)
                            (cons :n   the-n)   (cons :var  the-var)  (cons :pvar   the-pvar)   (cons :sumsq the-sumsq)))
         (stat-string (mapconcat (lambda (kv) (when (cdr kv)
                                                (let* ((s  (string-remove-prefix ":" (symbol-name (car kv))))
                                                       (v  (cdr kv))
                                                       (iv (if (< (abs (- v (truncate v))) zero-eps)
                                                               (truncate v)
                                                               v))
                                                       (fs (concat " %s: %0." (number-to-string prt-digits) "f"))
                                                       (np (format " %s: %s" s iv))
                                                       (fp (format fs        s v)))
                                                  (if (< (length np) (length fp))
                                                      np
                                                      fp)))) stat-alist)))
    (kill-new stat-string)
    (deactivate-mark)
    (message stat-string)
    stat-alist))

(provide 'mjr-stats-numbers-in-column)

;;; filename ends here
