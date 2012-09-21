(use srfi-19 posix)

(change-directory "~/db")

(let ((name (string-append "ktr-db-backup-" (date->string (current-date) "~m~d~y-~H~M-~S") (if (file-exists? "~/keep-the-records/i-am-staging") "-staging" ""))))
  (process-wait (process-run (string-append "cp ~/db/ktr-db-auto-backup ~/db/" name)))
  (print "backing up " name)
  (process-wait (process-run (string-append "/usr/local/bin/tarsnap -c -f " name " "  name)))
  (with-output-to-file "last-backup" (lambda () (write name)))
  (print "done backing up")
  (print "cleaning up")
  (process-wait (process-run (string-append "rm " name))))
