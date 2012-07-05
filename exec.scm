#!/usr/bin/csi

;cd /keep-the-records
;sudo nohup awful /keep-the-records/setup.scm port=8082 &

(use posix)
;(change-directory "/keep-the-records")

(process-run (string-append "nohup awful --port=" (car (command-line-arguments)) " keep-the-records &"))

(exit)
