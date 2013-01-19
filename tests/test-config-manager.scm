(import config-manager)

(test-begin "config-manager")

(test "read value"
      "dev" (read-config-value 'server-name (read-config-file "tests/config-file.scm")))

(test-end "config-manager")
