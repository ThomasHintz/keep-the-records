#!/usr/bin/csi -script
(use intarweb http-client uri-common posix)

(load "utils")

(define (log s)
  (with-output-to-file "/home/awful/monitor.log"
    (lambda () (display s) (flush-output))))

(define (monitor watch-uri watch-process kill-process)
  (do () (#f)
      (handle-exceptions exn
                         (begin (process-wait (process-run (string-append "killall -s 9 " kill-process)))
                                (sleep 1)
                                (process-wait (process-run watch-process))
                                (sleep 10))
                         (begin (get-code watch-uri)
                                (sleep 2)))))

(monitor "http://keeptherecords.com/" "/home/web/./exec" "awful")