;; [[ref:d353e10d-46ef-4971-ac82-a0f8d5b8f4c2][5.scm]]
;;
;; PostgreSQL service added to [[ref:2a0fc57a-d3ba-4789-9469-382d8ac62596][4.scm]]

(use-modules
 (gnu bootloader grub)
 (gnu bootloader)
 (gnu packages admin) ; shadow
 (gnu packages databases)
 (gnu services base)
 (gnu services databases)
 (gnu services shepherd)
 (gnu services)
 (gnu system file-systems)
 (gnu system keyboard)
 (gnu system)
 (guix gexp)
 (guix records)
 (ice-9 match)
 (ice-9 regex)
 )

;; ── Service type under test ───────────────────────────────────────────────────

;; ApplicationConf :≡ :lang × String
(define-record-type* <application-conf>
  application-conf make-application-conf
  application-conf?
  (lang application-conf-lang (default "en"))
  (name application-conf-name (default "application")))

(define (application-conf-check value)
  (unless (application-conf? value)
    (error "value is not a ApplicationConf: ~S" value)))

(define (application-conf-home conf)
  (application-conf-check conf)
  (string-append "/var/lib/" (application-conf-name conf)))

(define (application-master config)
  (application-conf-check config)
  (let* ((lang (application-conf-lang config))
         (msg (match lang
                ("fr" "Bonjour, monde!")
                ("en" "Application, world!")
                (lang (format #f "Unexpected lang: ~S" lang)))))
    (list
     (shepherd-service
      (provision '(application))
      (documentation "Print a greeting.")
      (start  #~(lambda _
                  (display #$msg)
                  (newline)
                  #t))
      (stop   #~(lambda _ #t))
      (one-shot? #t)))))

;; [[ref:109bc638-0220-4f10-8b08-82d995bc1752][Application and FHS]]
(define (application-fhs config)
  (let* ((name (application-conf-name config))
         (home (application-conf-home config))
         (dirs (list (string-append "/etc/"       name)
                     home
                     (string-append "/run/"       name)
                     (string-append "/var/log/"   name)
                     (string-append "/var/cache/" name)
                     (string-append "/usr/share/" name)
                     (string-append "/usr/lib/"   name))))
    #~(begin
        (use-modules (guix build utils))
        (for-each
         (lambda (dir) (mkdir-p dir) (chmod dir #o700))
         '#$dirs))))

;; [[ref:1fd5d002-cfc2-4556-8859-f79bd94d08e3][Linux and users]]
(define (application-accounts config)
  (let* ((name (application-conf-name config))
         (home (application-conf-home config)))
    (list
     (user-group
      (name name)
      (system? #t))
     (user-account
      (name name)
      (comment "Application user")
      (group name)
      (system? #t)
      (home-directory home)

      ;; [[ref:adc94f2b-b7de-4784-8e88-a992b390683e][nologin]]
      (shell #~(string-append #$shadow "/sbin/nologin"))))))

;; [[ref:f059b54e-66e9-4090-b3c3-d68f08259458][PostgreSQL]]
(define (application-database config)
  (let* ((name     (application-conf-name config))
         (pg_hba   "\
# TYPE  DATABASE  USER  ADDRESS  METHOD
local   all       all            peer  map=appmap")
         (pg_ident (regexp-substitute/global
                    #f "USER"
                    "\
# MAPNAME  SYSTEM-USERNAME  PG-USERNAME
appmap     USER             postgres
appmap     root             postgres"
                    'pre name 'post)))
    (service
     postgresql-service-type
     (postgresql-configuration
      (postgresql postgresql)
      (config-file
       (postgresql-config-file
        (hba-file   (plain-file "pg_hba.conf"   pg_hba))
        (ident-file (plain-file "pg_ident.conf" pg_ident))))))))

(define application-service-type
  (service-type
   (name 'application)
   (description "application")
   (extensions
    (list
     (service-extension shepherd-root-service-type application-master)
     (service-extension activation-service-type application-fhs)
     (service-extension account-service-type application-accounts)))
   (default-value (application-conf))))

;; ── OS ────────────────────────────────────────────────────────────────────────

(define configuration
  (application-conf
   (lang "fr")
   (name "application")))

(operating-system
 (host-name "test")
 (timezone  "Etc/UTC")
 (locale    "en_US.utf8")
 (keyboard-layout (keyboard-layout "fr"))

 (bootloader
  (bootloader-configuration
   (bootloader grub-bootloader)
   (targets '("/dev/vda"))
   (keyboard-layout keyboard-layout)))

 (file-systems
  (cons (file-system
         (mount-point "/")
         (device "/dev/vda1")
         (type "ext4"))
        %base-file-systems))

 (services
  (cons*
   (application-database configuration)
   (service application-service-type configuration)
   %base-services)))
