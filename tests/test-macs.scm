(import macs)

(test-begin "macs")

(test-group "make-global-parameter"
            (test-assert (make-global-parameter "x"))
            (test "x" ((make-global-parameter "x")))
            (test '("y") ((make-global-parameter '("y"))))
            (let ((test-param (make-global-parameter 'undefined)))
              (test 'undefined (test-param))
              (test-assert (test-param "food"))
              (test "food" (test-param))))

(test-end "macs")
