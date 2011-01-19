(use spiffy awful)

;;; production
;(load "production")
;;; end production

(load "utils.scm")
;(load "db")
;(load "db.sdbm.scm")
(load "mda.scm")
(load "storage-funcs.scm")
(load "pdf.scm")
(load "handlers.scm")

;(load "css-engine.scm")
(load "demo-data.scm")
(load "keep-the-records.scm")
;(load "sales")

;;; virtual host mapping
;(vhost-map `(("campnepco\\.com" .
;              ,(lambda (continue)
;                 (parameterize ((root-path "nepco/") (enable-ajax #t) (enable-session #t)
;                                (prefix-path "nepco")
;                                (valid-password?
;                                 (lambda (user password)
;                                   (if (user-exists? user)
;                                       (password-matches? user password)
;                                       #f))))
;                   (continue))))
;             ("troutfishingtime\\.com" .
;              ,(lambda (continue)
;                 (parameterize ((root-path "trout/"))
;                   (continue))))
;             ("localhost" . ,(lambda (continue)
;                               (parameterize ((root-path "nepco/") (enable-ajax #t) (enable-session #t)
;                                              (prefix-path "nepco")
;                                              (valid-password?
;                                               (lambda (user password)
;                                                 (if (not (eq? (db-read "nepco" "users" user) 'not-found))
;                                                     (password-matches? user password)
;                                                     #f))))
;                                 (continue))))
;             (".*" . ,(lambda (continue) (continue)))))