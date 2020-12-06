;; Docker COPY does not preserve mtimes.
;; So set the mtimes to something useful here.
(use-modules (guix build utils))
(use-modules (ice-9 format))
(for-each
  (lambda (name)
    (catch #t
      (lambda ()
        (utime name 1 1))
      (lambda _
        (format (current-error-port) "utime error on file ~a\n" name))))
  (find-files "/gnu/store" #:directories? #t #:stat stat))
