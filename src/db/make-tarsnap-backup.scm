(load "~/keep-the-records/src/config/config-manager") (import config-manager)
(if (read-general-config-value 'enable-backups #f)
(begin

(use srfi-19 posix http-client)

(change-directory "~/keep-the-records")
(define keyfile (read-general-config-value 'tarsnap-keyfile))

(let ((name (string-append "ktr-db-backup-" (date->string (current-date) "~m~d~y-~H~M-~S-") (read-general-config-value 'server-id))))
  (print "using keyfile " keyfile)
  (print "pausing db")
  (with-input-from-request "http://localhost:12000/site/admin/db/pause" #f read-string)
  (process-wait (process-run (string-append "cp ~/keep-the-records/ktr-db ~/keep-the-records/" name)))
  (print "resumeing db")
  (with-input-from-request "http://localhost:12000/site/admin/db/resume" #f read-string)
  (print "backing up to " name)
  (process-wait (process-run (string-append "/usr/local/bin/tarsnap -c -f " name " --keyfile " keyfile " "  name)))
  (print "removing last-backup")
  (process-wait (process-run (string-append "/usr/local/bin/tarsnap --keyfile " keyfile " -d -f last-backup")))
  (print "backing up to last-backup")
  (process-wait (process-run (string-append "/usr/local/bin/tarsnap -c -f last-backup --keyfile " keyfile " "  name)))
  (print "cleaning")
  (process-wait (process-run (string-append "rm " name)))
  (print "finished"))

)
(print "backups are disabled")
)
