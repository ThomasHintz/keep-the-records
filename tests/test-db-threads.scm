(use test srfi-18 srfi-1)
(load "src/utils/misc-utils")
(import misc-utils)
(load "src/db/db-interface")
(import db-interface)

(define (do-test)
  (let ((k (number->string (random 10000))))
    (db:store "v" k)
    (db:read k)))

(define (run-times test times i)
  (if (>= i times)
      #t
      (begin (test)
             (run-times test times (+ i 1)))))

(when (file-exists? "test-db-threads")
      (delete-file "test-db-threads"))
(db:path "test-db-threads")
(db:connect)

(test-begin "db threads")

(let ((threads (map (lambda (e) (make-thread (lambda () (run-times do-test 1000 0))))
                     (range 10))))
  (map (lambda (t) (thread-start! t)) threads)
  (map (lambda (t) (thread-join! t)) threads))
(test-assert #t)

(test-end "db threads")
