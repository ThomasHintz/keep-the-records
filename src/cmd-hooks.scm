(use posix)

(define (sync-ktr-setup)
  (e "su teejay")
  (change-directory "/home/teejay/thomas/programming/scheme/keep-the-records")
  (move-file "setup.scm" "setup.scm.bak")
  (move-file "setup.production.scm" "setup.scm"))

(define (sync-ktr-finish)
  (move-file "setup.scm" "setup.production.scm")
  (move-file "setup.scm.bak" "setup.scm")
  (e "exit"))

(define (sync-ktr-staging)
  (sync-ktr-setup)
  (e "rsync -aurtvv --exclude 'essays-in' --exclude 'nohup.out' --exclude 'ktr-db.dir' --exclude 'ktr-db.pag' -e ssh . webaccess@staging.keeptherecords.com:/keep-the-records | grep -v 'uptodate'")
  (sync-ktr-finish))

(define (sync-ktr-production)
  (sync-ktr-setup)
  (e "rsync -aurtvv --exclude 'essays-in' --exclude 'nohup.out' --exclude 'ktr-db.dir' --exclude 'ktr-db.pag' -e ssh . webaccess@keeptherecords.com:/keep-the-records | grep -v 'uptodate'")
  (sync-ktr-finish))

(define ktr-server-pid (make-parameter 0))
(define (start-ktr)
  (change-directory "/home/teejay/thomas/programming/scheme/keep-the-records/")
  (ktr-server-pid (process-run "awful setup.scm --development-mode")))

(define (stop-ktr)
  (e (string-append "kill -s 9 " (->string (ktr-server-pid)))))

(define (restart-ktr)
  (stop-ktr)
  (start-ktr))