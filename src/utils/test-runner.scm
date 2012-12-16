(use test posix srfi-13 srfi-1 easy-args)

(define-arguments
  ((filter-by f) "")
  ((compiled c) #f))

(define (run-tests test-files src-root test-root suffix)
  (map (lambda (files)
         (load (string-append src-root (car files) suffix))
         (load (string-append test-root (cadr files) ".scm")))
       test-files))

(define (test-filter test-files filter-by)
      (filter (lambda (files) (string-contains (car files) filter-by)) test-files))

(change-directory "~/keep-the-records")

(test-begin "all")
(run-tests
 (test-filter
  '(("utils/date-time-utils" "test-date-time-utils")
    ("utils/misc-utils" "test-misc-utils"))
  (filter-by))
 "src/" "tests/" (if (compiled) "" ".scm"))
(test-end "all")
