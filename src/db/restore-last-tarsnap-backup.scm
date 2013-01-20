(use posix)
(load "~/keep-the-records/src/config/config-manager") (import config-manager)

(change-directory "~/")

(print "writing to ~/")
(process-wait (process-run (string-append "/usr/local/bin/tarsnap --keyfile " (read-general-config-value 'tarsnap-keyfile) " -x -f last-backup")))
(print "done")
