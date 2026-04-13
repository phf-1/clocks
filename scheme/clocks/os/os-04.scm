;; [[id:2a0fc57a-d3ba-4789-9469-382d8ac62596][4.scm]]
;;
;; Application's user added to [[ref:62f9fc4b-787a-4c1f-9bbf-e57e1b8bfec5][3.scm]]

(use-modules
 (gnu system)
 (gnu system file-systems)
 (gnu bootloader)
 (gnu bootloader grub)
 (gnu services)
 (gnu services base)
 (gnu services shepherd)
 (gnu system keyboard)
 (gnu packages admin) ; shadow
 (ice-9 match)
 (guix gexp)
 (guix records))

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
  (cons (service application-service-type
                 (application-conf
                  (lang "fr")
                  (name "application")))
        %base-services)))
