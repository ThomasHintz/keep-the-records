#!/usr/bin/csi

;cd /keep-the-records
;sudo nohup awful /keep-the-records/setup.scm port=8082 &

(use posix)
(change-directory "/keep-the-records")

(with-output-to-file "ktr-pid"
  (lambda ()
    (write (process-run "sudo nohup awful /keep-the-records/setup.scm port=8082"))))