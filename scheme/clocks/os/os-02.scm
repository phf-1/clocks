;; [[id:ade76fc8-1488-46e8-920e-d185a80b58f7][2.scm]]
;;
;; Configuration capabilities added.

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

;; HelloConf :≡ :lang × String
(define-record-type* <hello-conf>
  hello-conf make-hello-conf
  hello-conf?
  (lang hello-conf-lang (default "en")))

(define (hello-conf-check value)
  (unless (hello-conf? value)
    (error "value is not a HelloConf: ~S" value)))

(use-modules (ice-9 match))
(define (hello-shepherd-service config)
  (hello-conf-check config)
  (let* ((lang (hello-conf-lang config))
         (msg (match lang
                ("fr" "Bonjour, monde!")
                ("en" "Hello, world!")
                (lang (format #f "Unexpected lang: ~S" lang)))))
    (list
     (shepherd-service
      (provision '(hello))
      (documentation "Print a greeting.")
      (start  #~(lambda _
                  (display #$msg)
                  (newline)
                  #t))
      (stop   #~(lambda _ #t))
      (one-shot? #t)))))

(define hello-service-type
  (service-type
   (name 'hello)
   (description "hello")
   (extensions
    (list (service-extension
           shepherd-root-service-type
           hello-shepherd-service)))
   (default-value (hello-conf))))

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
  (cons (service hello-service-type (hello-conf (lang "fr")))
        %base-services)))
