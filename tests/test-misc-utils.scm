(import misc-utils)

(test-begin "misc-utils")

(test-group
 "fold-sep"
 (test "xa*/b*/c*" (fold-sep (lambda (e) (string-append e "*")) "/" "x" '("a" "b" "c"))))

(test-group
 "range"
 (test '() (range 0))
 (test '(0) (range 1))
 (test '(0) (range 0 1))
 (test '(0 1) (range 2))
 (test '(0 1) (range 0 2))
 (test '(1 2) (range 1 3))
 (test '(-2 -1) (range -2 0))
 (test-error (range -10))
 (test-error (range 0 -10)))

(test-group
 "dash->space"
 (test "a b c" (dash->space "a-b-c")))

(test-group
 "space->dash"
 (test "a-b-c" (space->dash "a b c")))

(test-group
 "id->name"
 (test "Eat Good" (id->name "eat-good")))

(test-group
 "name->id"
 (test "eat-good" (name->id "Eat Good")))

(test-group
 "list->path"
 (test "/a/b/c" (list->path '("a" "b" "c") "/")))

(test-group
 "html-escape"
 (test "eat&apos;stuff&apos; food" (html-escape "eat'stuff' food")))

(test-group
 "js-filter"
 (test "eatstuff food" (js-filter "eat'stuff' food")))

(test-end "misc-utils")
