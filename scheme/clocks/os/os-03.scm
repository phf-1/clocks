;; [[id:62f9fc4b-787a-4c1f-9bbf-e57e1b8bfec5][3.scm]]
;;
;; FHS added to [[ref:ade76fc8-1488-46e8-920e-d185a80b58f7][2.scm]]

(use-modules
 (gnu system)
 (gnu system file-systems)
 (gnu bootloader)
 (gnu bootloader grub)
 (gnu services)
 (gnu services base)
 (gnu services shepherd)
 (gnu system keyboard)
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

(use-modules (ice-9 match))
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
         (dirs (list (string-append "/etc/"       name)
                     (string-append "/var/lib/"   name)
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

(define application-service-type
  (service-type
   (name 'application)
   (description "application")
   (extensions
    (list
     (service-extension shepherd-root-service-type application-master)
     (service-extension activation-service-type application-fhs)))
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
