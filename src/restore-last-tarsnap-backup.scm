(use posix)

(change-directory "~/db")

(print "fetching")
(process-wait (process-run (string-append "/usr/local/bin/tarsnap -x -f " (with-input-from-file "last-backup" (lambda() (read))))))
(print "done")
