#!/usr/bin/csi

;rsync -aurtvv --exclude 'essays-in' --exclude 'nohup.out' --exclude 'ktr-db.dir' --exclude 'ktr-db.pag' -e ssh . webaccess@staging.keeptherecords.com:/keep-the-records | grep -v 'uptodate'

;rsync -naurtvv --exclude '.git' --exclude 'essays-in' --exclude 'nohup.out' --exclude 'ktr-db' -e ssh . webaccess@thintz.com:/keep-the-records | grep -v 'uptodate'

(use shell)

; dry run
(run "rsync -naurtvv --exclude '.git' --exclude 'essays-in' --exclude 'nohup.out' --exclude 'ktr-db' --exclude '.gitignore' --exclude 'config.rb' --exclude '*~' --exclude '.sass*' --exclude 'scss' --exclude '*.scss' -e ssh . webaccess@a.keeptherecords.com:/keep-the-records | grep -v 'uptodate'")
(display "continue? ")
(if (string=? (read) "y")
    (run "rsync -aurtvv --exclude '.git' --exclude 'essays-in' --exclude 'nohup.out' --exclude 'ktr-db' --exclude 'scss' --exclude '.gitignore' --exclude 'config.rb' --exclude '*~' --exclude '.sass*' --exclude '*.scss' -e ssh . webaccess@a.keeptherecords.com:/keep-the-records | grep -v 'uptodate'")
    #f)
(exit)
