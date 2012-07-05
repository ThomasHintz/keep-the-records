#!/usr/bin/csi

(use amazon-s3 send-grid srfi-19 shell)

(define *root* "/keep-the-records/")
(define ++ string-append)

(define (insert-file path)
  (with-input-from-file path (lambda () (read-string))))

(print "loading/setting send-grid api keys")

(define api-user (insert-file (++ *root* "send-grid-user")))
(define api-key (insert-file (++ *root* "send-grid-key")))

(handle-exceptions
 exn
 (send-mail from: "error@keeptherecords.com" from-name: "Error" to: "t@thintz.com" reply-to: "error@keeptherecords.com" subject: "Database backup job failed"
	    html: "Database backup job failed")
 (begin

   (print "loading/setting aws api keys")
   (load (++ *root* "aws-setup.scm"))

   (https #t)

   (define bucket (make-parameter "keep-the-records-backup-job"))

   (define (space->dash s)
     (string-fold (lambda (c o) (string-append o (if (char=? #\space c) "-" (->string c)))) "" s))

   (define (remove-colons s)
     (string-fold (lambda (c o) (string-append o (if (char=? #\: c) "" (->string c)))) "" s))

   (print "copying file")
   (run "cp /keep-the-records/ktr-db /keep-the-records/ktr-db.bak")
   (print "file copied")

   (print "uploading...")
   (put-file! (bucket) (remove-colons (space->dash (date->string (current-date) "~c"))) (++ *root* "ktr-db"))
   (print "uploaded")

   (print "sending success mail")
   (send-mail from: "success@keeptherecords.com" from-name: "Success" to: "t@thintz.com" reply-to: "success@keeptherecords.com" subject: "Database backup job succeeded"
	    html: "Database backup job succeeded")
   (print "done")))

(exit)
