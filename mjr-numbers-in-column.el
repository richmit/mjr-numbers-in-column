;;; mjr-numbers-in-column.el --- statstics -*- lexical-binding:t; coding: utf-8; mode:emacs-lisp; fill-column:158 -*-

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
;; Version:     2.0
;; Keywords:    mjr-numbers-in-column
;; URL:         https://github.com/richmit/mjr-numbers-in-column

;; This file is not part of Emacs

;;; Commentary:
;;
;; See the README: https://github.com/richmit/mjr-numbers-in-column/
;;
;; This package provides an easy way to extract data arranged in a column and compute various statistics.
;;
;; Two functions are provided:
;;  - `mjr-numbers-in-column-extract' to extract data from a column.
;;  - `mjr-numbers-in-column-stats' to compute statstics for data in a column
;;
;; For example, we might be looking at the following "vmstat" output and want to know the average value for the "in" column.
;;
;;       $ vmstat 1 10
;;
;;       procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
;;        r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
;;        0  0  89032 21592880    0      0    0    0     0     0 2413 3604  0  2 98  0  0  0
;;        0  0  89032 21593640    0      0    0    0     0     0 1994 3036  1  2 97  0  0  0
;;        0  0  89032 21593620    0      0    0    0     0     0 1989 3043  1  3 96  0  0  0
;;        0  0  89032 21595388    0      0    0    0     0     0 2084 3299  0  0 100 0  0  0
;;        0  0  89032 21593396    0      0    0    0     0     0 2311 3710  0  1 99  0  0  0
;;        0  0  89032 21592160    0      0    0    0     0     0 1861 3030  0  1 99  0  0  0
;;        0  0  89032 21592184    0      0    0    0     0     0 1996 3034  1  3 96  0  0  0
;;        0  0  89032 21592664    0      0    0    0     0     0 2190 3283  1  3 96  0  0  0
;;        0  0  89032 21592284    0      0    0    0     0     0 2121 3174  1  4 95  0  0  0
;;
;; All we have to do is put our cursor on any digit of 2413 in the first row and run `mjr-numbers-in-column-stats' to get the following:
;;
;;       sum: 18959 mean: 2106.55556 median: 2084 min: 1861 max: 2413 sd: 164.11183
;;       psd: 174.06688 range: 552 n: 9 var: 26932.69136 pvar: 30299.27778 sumsq: 40180581
;;
;; So the average is 2106 with a standard deviation of 164.11183.
;;
;; The easiest way to install mjr-stats-numbers-in-column is to pull it directly from github:
;;
;;      (package-vc-install (list 'mjr-stats-numbers-in-column
;;                           :url "https://github.com/richmit/mjr-stats-numbers-in-column"
;;                           :rev 'newest))

;;; Code:

(require 'dired)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defgroup mjr-stats-numbers-in-column nil
  "mjr-stats-numbers-in-column"
  :group 'convenience
  :group 'development)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defcustom mjr-numbers-in-column-stats-num-digits-max 5
  "Maximum number of digits after the decimal point `mjr-numbers-in-column-stats' will print in results."
  :type '(choice (const  1) (const  2) (const  3) (const  4) (const  5) (const  6) (const  7) (const  8)
                 (const  9) (const 10) (const 11) (const 12) (const 13) (const 14) (const 15) (const 16))
  :group 'mjr-numbers-in-column-stats)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defcustom mjr-numbers-in-column-stats-stats-print '(:sum :mean :median :min :max :sd :range :n :var)
  "The stats `mjr-numbers-in-column-stats' will include in the printed message when run interactively."
  :type '(repeat (choice (const :sum)   (const :mean) (const :median) (const :min)  (const :max)   (const :sd)   (const :psd)
                         (const :range) (const :n)    (const :var)    (const :pvar) (const :sumsq)))
  :group 'mjr-numbers-in-column-stats)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defcustom mjr-numbers-in-column-stats-stats-return '(:sum :mean :median :min :max :sd :psd :range :n :var :pvar :sumsq :data)
  "The stats `mjr-numbers-in-column-stats' will return."
  :type '(repeat (choice (const :sum)   (const :mean) (const :median) (const :min)  (const :max)   (const :sd)  (const :psd)
                         (const :range) (const :n)    (const :var)    (const :pvar) (const :sumsq) (const :data)))
  :group 'mjr-numbers-in-column-stats)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-numbers-in-column-extract (start end)
  "Extract numbers arranged in a column return them as a list and, when called interactively, place a string on the kill ring.

When run interactively the column of numbers is identified in one of two ways:
  * Rectangular .. With an active, rectangular region -- one number per line of the rectangle
  * Point ........ Number found under the point, and continues to subsequent lines below the current one until a line is reached with no number.
When called non-interactively the rectangle method is used when start != end, otherwise the point method is used.
The point will be moved to the end of the last number found as a visual queue to the user when the point method is used."
  (interactive (if (and transient-mark-mode (region-active-p) (not (= (region-beginning) (region-end))))
                   (list (region-beginning) (region-end))
                   (list (point) (point))))
  (let* ((num-rex "[-+]?\\([0-9]+\\.?[0-9]*\\|\\.[0-9]+\\)\\([eE][-+]?[0-9]+\\)?")
         (num-str (if (not (= start end))
                      (mapcar (lambda (s) (substring-no-properties s)) (extract-rectangle start end))
                      (let ((seed-string-number (and (goto-char start) (thing-at-point-looking-at num-rex 40) (match-string 0))))
                        (if (not seed-string-number)
                            (error "mjr-numbers-in-column-stats: ERROR: Point not on number!")
                            (let ((target-column          (current-column))
                                  (list-of-number-strings (list seed-string-number)))
                              (while (when (and (zerop (forward-line 1)) (= (point) (pos-bol)))
                                       (when (= target-column (move-to-column target-column 't))
                                         (when-let ((nap (and (thing-at-point-looking-at num-rex 40) (match-string 0))))
                                           (setq list-of-number-strings (cons nap list-of-number-strings))))))
                              (reverse list-of-number-strings))))))
         (num-flt (mapcar (lambda (s) (float (string-to-number s))) num-str)))
    (if (called-interactively-p 'any)
        (kill-new (message (format "%S" num-flt))))
    num-flt))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mjr-compute-stats (data)
  "Compute statistics for a list of floating point numbers, and return the statistics in an alist."
  (let* ((sorted-data (sort (cl-copy-list data) #'<))
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
         (the-range   (- the-max the-min)))
    (list (cons :sum the-sum) (cons :mean the-mean) (cons :median the-median) (cons :min   the-min)
          (cons :max the-max) (cons :sd   the-sd)   (cons :psd    the-psd)    (cons :range the-range)
          (cons :n   the-n)   (cons :var  the-var)  (cons :pvar   the-pvar)   (cons :sumsq the-sumsq))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-numbers-in-column-stats (start end)
  "Compute statistics for numbers in a column.  Results are  put on the kill ring.

Uses `mjr-numbers-in-column-extract' to get the data.  This function returns an alist of statistics specified in the variable
`mjr-numbers-in-column-stats-stats-return'.  When called interactively a summary is printed and placed on the kill ring -- see
`mjr-numbers-in-column-stats-num-digits-max' and `mjr-numbers-in-column-stats-stats-print'."
  (interactive (if (and transient-mark-mode (region-active-p) (not (= (region-beginning) (region-end))))
                   (list (region-beginning) (region-end))
                   (list (point) (point))))
  (let* ((data        (mjr-numbers-in-column-extract start end))
         (stat-alist  (mjr-compute-stats data))
         (sig-digits  (apply #'max (mapcar (lambda (x) (length (replace-regexp-in-string "0+e.*$" "" (format "%.50e" x)))) data)))         
         (prt-digits  (min sig-digits
                           (if (and (integerp mjr-numbers-in-column-stats-num-digits-max) (< 0 mjr-numbers-in-column-stats-num-digits-max))
                               mjr-numbers-in-column-stats-num-digits-max
                               5)))
         (zero-eps    (expt 10 (- (+ 2 prt-digits))))
         (stat-string (mapconcat (lambda (k) (when-let* ((s  (string-remove-prefix ":" (symbol-name k)))
                                                         (v  (cdr (assoc k stat-alist)))
                                                         (iv (if (< (abs (- v (truncate v))) zero-eps)
                                                                 (truncate v)
                                                                 v))
                                                         (fs (concat " %s: %0." (number-to-string prt-digits) "f"))
                                                         (np (format " %s: %s" s iv))
                                                         (fp (format fs        s v)))
                                                  (if (< (length np) (length fp))
                                                      np
                                                      fp))) mjr-numbers-in-column-stats-stats-print)))
    (kill-new stat-string)
    (deactivate-mark)
    (when (called-interactively-p 'any)
      (message stat-string))
    (mapcar (lambda (k) (assoc k stat-alist)) mjr-numbers-in-column-stats-stats-return)))

(provide 'mjr-numbers-in-column-stats)


;; Some Test Dat
;;
;; 123
;;  234
;;   567  
;;    
;;  sum: 924 mean: 308 median: 234 min: 123 max: 567 sd: 188.6637 psd: 231.0649 range: 444 n: 3 var: 35594 pvar: 53391 sumsq: 391374
;;  sum: 924 mean: 308 median: 234 min: 123 max: 567 sd: 188.6637 range: 444 n: 3 var: 35594

;; (mjr-install-mjr-packages :reinstall :git 'mjr-numbers-in-column)

;;; mjr-numbers-in-column.el ends here
