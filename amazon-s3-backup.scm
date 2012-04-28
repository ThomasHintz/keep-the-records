#!/usr/bin/csi

(use amazon-s3 srfi-19)

(load "aws-setup.scm")

(https #t)

(define bucket (make-parameter "keep-the-records-backup-job"))

(define (space->dash s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\space c) "-" (->string c)))) "" s))

(define (remove-colons s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\: c) "" (->string c)))) "" s))

(put-file! (bucket) (remove-colons (space->dash (date->string (current-date) "~c"))) "ktr-db")
(exit)