#!/usr/local/bin/csi -script
;; -*- scheme -*-

(declare (uses chicken-syntax))
(use awful spiffy)
(trusted-proxies '("127.0.0.1"))

(awful-start
 (lambda ()
   (load-apps '("keep-the-records")))
 port: 12000)
