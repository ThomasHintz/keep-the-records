(use mda-client zmq posix)

(define socket #f)

(define (setup-socket)
  (set! socket (make-socket 'req))
  (connect-socket socket "tcp://localhost:4445"))
(setup-socket)

(db:pause)
(print "paused")
(print "begin copying")
(process-wait (process-run "cp ~/db/ktr-db ~/db/ktr-db-auto-backup"))
(print "done copying")
(send-message socket "unpause")
(receive-message* socket)
(print "unpaused")
