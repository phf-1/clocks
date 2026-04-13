;; [[id:96a9de83-1855-4fd8-b925-4102a3830b55][7.scm]]
;;
;; nginx added to [[ref:08d1bc16-e3eb-4f45-87fa-a2039653f718][6.scm]]

(use-modules
 ((clocks constant) #:prefix cst:)
 (gnu bootloader grub)
 (gnu bootloader)
 (gnu packages admin) ; shadow
 (gnu packages databases)
 (gnu services base)
 (gnu services databases)
 (gnu services shepherd)
 (gnu services web)
 (gnu services)
 (gnu system file-systems)
 (gnu system keyboard)
 (gnu system)
 (guix gexp)
 (guix records)
 (ice-9 match)
 (ice-9 regex))

;; ── Service type under test ───────────────────────────────────────────────────

;; ApplicationConf :≡ :lang × String
(define-record-type* <application-conf>
  application-conf make-application-conf
  application-conf?
  (lang application-conf-lang (default "en"))
  (name application-conf-name (default "application"))
  (port application-conf-port (default "4000"))
  (host-name application-conf-host-name (default "localhost")))

(define (application-conf-check value)
  (unless (application-conf? value)
    (error "value is not a ApplicationConf: ~S" value)))

(define (application-conf-home conf)
  (application-conf-check conf)
  (string-append "/var/lib/" (application-conf-name conf)))

(define (application-conf-etc conf)
  (application-conf-check conf)
  (string-append "/etc/" (application-conf-name conf)))

(define (application-conf-certs conf)
  (application-conf-check conf)
  (string-append (application-conf-etc conf) "/certs"))

(define (application-conf-cert conf)
  (application-conf-check conf)
  (string-append (application-conf-certs conf) "/dev-cert.pem"))

(define (application-conf-cert-key conf)
  (application-conf-check conf)
  (string-append (application-conf-certs conf) "/dev-cert.key"))

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
  (application-conf-check config)
  (let* ((name (application-conf-name config))
         (home (application-conf-home config))
         (etc (application-conf-etc config))
         (dirs (list etc
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
  (application-conf-check config)
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
  (application-conf-check config)
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

;; TODO(2e7d): there must be a distinction between dev and prod mode since in
;; production mode certificates are obtained from cert bots instead of locally signed
;; ones reserved for development.
(define (application-certs config)
  (application-conf-check config)
  (let* ((certs (application-conf-certs config))
         (host-cert (local-file (string-append cst:certs-root "/dev-cert.pem")))
         (cert (application-conf-cert config))
         (host-cert-key (local-file (string-append cst:certs-root "/dev-key.pem")))
         (cert-key (application-conf-cert-key config)))
    #~(begin
        (use-modules (guix build utils))
        (mkdir-p #$certs)
        (chmod #$certs #o700)
        (copy-file #$host-cert #$cert)
        (chmod #$cert #o644)
        (copy-file #$host-cert-key #$cert-key)
        (chmod #$cert-key #o600))))

(define (application-activation config)
  (application-conf-check config)
  (let ((fhs (application-fhs   config))
        (certs (application-certs config)))
    #~(begin #$fhs #$certs)))

(define (application-reverse-proxy config)
  (application-conf-check config)
  (let* ((port (application-conf-port config))
         (cert (application-conf-cert config))
         (cert-key (application-conf-cert-key config))
         (host-name (application-conf-host-name config))
         (host-name-list (list host-name (string-append "www." host-name))))
    (service
     nginx-service-type
     (nginx-configuration
      (server-blocks
       (list
        (nginx-server-configuration
         (server-name host-name-list)
         (listen '("80"))
         (raw-content '("return 301 https://$host$request_uri;")))

        (nginx-server-configuration
         (server-name host-name-list)
         (listen '("443 ssl"))
         (ssl-certificate cert)
         (ssl-certificate-key cert-key)
         (locations
          (list
           (nginx-location-configuration
            (uri "/")
            (body
             (list
              "proxy_set_header X-Real-IP $remote_addr;"
              "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
              "proxy_set_header X-Forwarded-Proto https;"
              "proxy_set_header Host $host;"
              (string-append "proxy_pass http://localhost:" port ";")
              "proxy_http_version 1.1;"
              "proxy_set_header Connection \"\";"
              "proxy_connect_timeout 10s;"
              "proxy_read_timeout 60s;"
              "proxy_send_timeout 60s;"))))))))))))

(define application-service-type
  (service-type
   (name 'application)
   (description "application")
   (extensions
    (list
     (service-extension shepherd-root-service-type application-master)
     (service-extension activation-service-type application-activation)
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
   (application-reverse-proxy configuration)
   (application-database configuration)
   (service application-service-type configuration)
   %base-services)))
