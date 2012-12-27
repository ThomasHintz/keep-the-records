(import sections)

(test-begin "sections")

(test-group
 "ad"
 (test '("Hopper" "Jumper") (ad "Cubbies" 'book))
 (test '("Cubbies" "Sparks" "TnT") (ad 'asdf))
 (test '("Cubbies" "Sparks" "TnT") (ad 'club))
 (test-error (ad "eat" 'book))
 (test-error (ad "eat"))
 (test-error (ad 'a 'b 'c 'd 'e 'f)))

(test-end "sections")
