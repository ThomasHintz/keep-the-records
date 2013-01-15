(use test srfi-18 srfi-1)
(load "src/utils/misc-utils") (import misc-utils)
(load "src/db/db-interface") (import db-interface)
(load "src/utils/threading-extras") (import threading-extras)

(define (do-test)
  (let ((k (number->string (random 10000))))
    (db:store "v" k)
    (db:read k)))

(define (run-times test times i)
  (if (>= i times)
      #t
      (begin (test)
             (run-times test times (+ i 1)))))

(define (pause/resume)
  (db:pause)
  (thread-sleep! 1)
  (db:resume)
  (thread-sleep! 1))

(define (terminate-rnd-thread threads)
  (thread-terminate! (list-ref threads (random (length threads)))))

(when (file-exists? "test-db-threads")
      (delete-file "test-db-threads"))
(db:path "test-db-threads")
(db:connect)

(test-begin "db threads")

(test-assert "multi-threaded db interaction"
 (let ((threads (map (lambda (e)
                       (make-thread (lambda () (run-times do-test 100 0))))
                     (range 100)))
       (pauser (make-thread (lambda () (run-times pause/resume 3 0)))))
   (thread-start! pauser)
   (map (lambda (t) (thread-start! t)) threads)
   (thread-yield!)
   (map (lambda (t) (thread-join! t)) threads)
   (thread-join! pauser)))

(test-assert "multi-threaded db interaction with destroyer thread"
 (let* ((threads (map (lambda (e)
                        (make-thread (lambda () (run-times do-test 1000 0))))
                      (range 100)))
        (pauser (make-thread (lambda () (run-times pause/resume 3 0))))
        (chaos-monkey (make-thread (lambda ()
                                     (run-times (lambda ()
                                                  (thread-sleep! 1)
                                                  (terminate-rnd-thread threads))
                                                3 0)))))
   (thread-start! pauser)
   (thread-start! chaos-monkey)
   (map (lambda (t) (thread-start! t)) threads)
   (thread-yield!)
   (map (lambda (t) (thread-join! t)) threads)
   (thread-join! chaos-monkey)
   (thread-join! pauser)))

(test-end "db threads")
