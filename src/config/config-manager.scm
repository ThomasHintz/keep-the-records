; author: Thomas Hintz
; email: t@thintz.com
; license: bsd

; Copyright (c) 2012-2013, Thomas Hintz
; All rights reserved.

; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;     * Redistributions of source code must retain the above copyright
;       notice, this list of conditions and the following disclaimer.
;     * Redistributions in binary form must reproduce the above copyright
;       notice, this list of conditions and the following disclaimer in the
;       documentation and/or other materials provided with the distribution.
;     * Neither the name of the author nor the
;       names of its contributors may be used to endorse or promote products
;       derived from this software without specific prior written permission.

; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THOMAS HINTZ BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; 	    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; 	    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; 	    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; 	    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(module config-manager
  (
   read-config-file read-config-value read-general-config-file read-general-config-value
   )

(import scheme chicken ports data-structures)

(define (read-config-file path)
  (with-input-from-file path (lambda () (read))))

(define (read-config-value key config-list #!key (test equal?) (default ""))
  (alist-ref key config-list test default))

(define (read-general-config-file)
  (read-config-file "~/keep-the-records/etc/general.scm"))

(define (read-general-config-value key #!key (test equal?) (default ""))
  (read-config-value key (read-general-config-file) test: test default: default))

)
