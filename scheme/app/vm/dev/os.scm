;; [[id:e19c7bb6-c331-4aa8-ba15-9c8cd6156166][DevOS]]
;;
;; This module defines dev : OS, as an extension of [[ref:7f1cb335-753f-448b-9637-39c130ded682][init]] : OS.

(define-module (app vm dev os))

(use-modules
 ((gnu services))
 ((gnu services databases))
 ((gnu packages databases))
 ((gnu system))
 ((guix gexp))
 ((app vm init os) #:prefix init:)
 ((app vm dev package) #:prefix dev:))

;; We start from services and packages of init : OS
(define services (operating-system-user-services init:os))
(define packages (operating-system-packages init:os))

;; A PostgreSQL instance should be running and associated package for local
;; diagnostics. TODO(e57f): for some reason, we need to run initdb ourself if
;; necessary.
(define postgresql-initdb-service
  (simple-service
   'postgresql-initdb
   activation-service-type
   #~(begin
       (use-modules (guix build utils))
       (let ((data-dir "/var/lib/postgresql/data"))
         (unless (file-exists? (string-append data-dir "/PG_VERSION"))
           (mkdir-p data-dir)
           (chown data-dir
                  (passwd:uid (getpwnam "postgres"))
                  (passwd:gid (getpwnam "postgres")))
           (invoke "su" "-s" "/bin/sh" "postgres"
                   "-c" (string-append "initdb -D " data-dir)))))))
(set! services (cons postgresql-initdb-service services))
(define postgresql-service
  (service
   postgresql-service-type
   (postgresql-configuration
    (postgresql postgresql))))
(set! services (cons postgresql-service services))
(set! packages (cons postgresql packages))

;; TODO(7d53): nginx
;; TODO(bea0): syslogd
;; TODO(b691): rotating logs
;; TODO(f529): add dev:package
;; TODO(f529): add dev:service

;; Finally, the operating is defined as an extension of init : OS
(define-public os
  (operating-system
   (inherit init:os)
   (host-name "dev-os")
   (packages packages)
   (services services)))

;; So that `guix system image -t qcow2 /…/os.scm' works
os
