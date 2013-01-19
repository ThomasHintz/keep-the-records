(import db-interface)

(test-begin "db-interface")

(test-group "setup"
            (when (file-exists? "test-db")
                  (delete-file "test-db"))
            (test-assert (db:path "test-db"))
            (test-assert (db:flags
                          (fx+ db:flag-no-lock (fx+ db:flag-writer
                                                    (fx+ db:flag-reader db:flag-create)))))
            (test-assert (db:connect)))

(test-group "basics"
            (test 'not-found (db:read "a" "b" "c"))
            (test-assert (db:store "v" "k"))
            (test "v" (db:read "k"))
            (test-assert (db:store "v2" "a" "b" "c"))
            (test "v2" (db:read "a" "b" "c"))

            (test-assert (db:store "asdf" "x" "y" "z"))
            (test "asdf" (db:read "x" "y" "z"))
            (test-assert (db:delete "x" "y" "z"))
            (test 'not-found (db:read "x" "y" "z")))

(test-group "types"
            (test-assert "store lists" (db:store '(a b c) "test-lists"))
            (test "read lists" '(a b c) (db:read "test-lists"))
            (test-assert "store numbers" (db:store 24 "test-numbers"))
            (test "read numbers" 24 (db:read "test-numbers"))
            (test-assert "store code" (db:store '(define (x z) z) "test-code"))
            (test "read code" '(define (x z) z) (db:read "test-code")))

(test-group "lists"
            (test "default empty list" '() (db:list "an-index"))
            (test-assert "update empty list" (db:update-list 'x "an-index"))
            (test '(x) (db:list "an-index"))
            (test-assert "update non-empty list" (db:update-list 'y "an-index"))
            (test '(y x) (db:list "an-index"))
            (test-assert "update duplicate" (db:update-list 'x "an-index"))
            (test '(y x) (db:list "an-index"))
            (test-assert "remove from list" (db:remove-from-list 'x "an-index"))
            (test '(y) (db:list "an-index"))
            (test-assert "remove nonexistent from list" (db:remove-from-list 'x "an-index"))
            (test '(y) (db:list "an-index"))
            (test-assert "remove last" (db:remove-from-list 'y "an-index"))
            (test '() (db:list "an-index"))
            (test-assert "remove from empty list" (db:remove-from-list 'a "an-index"))
            (test '() (db:list "an-index")))

(test-group "disconnect"
            (test-assert (db:disconnect)))

(test-group "different sep"
            (when (file-exists? "test-db")
                  (delete-file "test-db"))
            (db:path "test-db")
            (db:sep "$$$")
            (db:connect)

            (test 'not-found (db:read "a" "b" "c"))
            (test-assert (db:store "v" "k"))
            (test "v" (db:read "k"))
            (test-assert (db:store "v2" "a" "b" "c"))
            (test "v2" (db:read "a" "b" "c"))

            (test-assert (db:store "asdf" "x" "y" "z"))
            (test "asdf" (db:read "x" "y" "z"))
            (test-assert (db:delete "x" "y" "z"))
            (test 'not-found (db:read "x" "y" "z")))

(test-group "pause/resume"
            (test #f (db:paused?))
            (test-assert (db:pause))
            (test #t (db:paused?))
            (test-assert (db:resume))
            (test #f (db:paused?)))

(when (file-exists? "test-db")
      (delete-file "test-db"))

(test-end "db-interface")
