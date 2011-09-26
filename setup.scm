(use spiffy awful)

(define is-production? (make-parameter (file-exists? "/keep-the-records/i-am-production")))

;;; production
(if (is-production?) (load "production") #f)
;;; end production

(load "macs.scm")
(load "utils.scm")
(load "mda.scm")
(load "storage-funcs.scm")
(load "pdf.scm")
(load "handlers.scm")
(load "rest.scm")
(load "demo-data.scm")
(load "sections.scm")
(load "sessions.scm")

(load "keep-the-records.scm")