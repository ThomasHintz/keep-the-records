#!/usr/bin/csi -script
(use intarweb http-client uri-common posix)

(load "utils")
(load "rest")

(change-directory "/keep-the-records")
(define (monitor watch-uri start-process kill-process-id)
  (do () (#f)
      (handle-exceptions exn
                         (begin (process-wait (process-run (string-append "kill -s 9 " (->string kill-process-id))))
                                (sleep 1)
                                (process-wait (process-run start-process))
				(send-mail subject: "KtR died" html: "why?" from: "monitor@keeptherecords.com"
						   from-name: "Jackie" to: "t@thintz.com" reply-to: "monitor@keeptherecords.com")
                                (sleep 10))
                         (begin (get-code watch-uri)
                                (sleep 2)))))

(monitor "https://keeptherecords.com/user/login" "./exec.scm" (with-input-from-file "ktr-pid" (lambda () (read))))