(use spiffy awful)

(define is-production? (make-parameter (file-exists? "/keep-the-records/i-am-production")))

;;; production
(if (is-production?) (load "production") #f)
;;; end production

(load "macs")
(load "utils")
;(load "mda.scm")
(load "mda-client")
(load "storage-funcs")
(load "pdf")
(load "handlers")
(load "rest")
(load "demo-data")
(load "sections")
(load "awana-data-dsl")
(load "sessions")

(load "keep-the-records")
