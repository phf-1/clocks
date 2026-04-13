;; [[id:26064235-162b-423e-b978-8797f786f3bf][1.scm]]
;;
;; Minimal OS for iterating on a custom service type.
;; Boot it with: guix system vm test-os.scm && ./result

(use-modules
 (gnu system)
 (gnu system file-systems)
 (gnu bootloader)
 (gnu bootloader grub)
 (gnu services)
 (gnu services base)
 (gnu services shepherd)
 (gnu system keyboard)
 (guix gexp))

;; ── Service type under test ───────────────────────────────────────────────────

(define (hello-shepherd-service config)
  (list
   (shepherd-service
    (provision     '(hello))
    (documentation "Print a greeting and exit.")
    (start  #~(lambda _
                (display "Hello, world!")
                (newline)
                #t))
    (stop   #~(lambda _ #t))
    (one-shot? #t))))

(define hello-service-type
  (service-type
   (name 'hello)
   (description "description")
   (extensions
    (list (service-extension
           shepherd-root-service-type
           hello-shepherd-service)))
   (default-value #f)))

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
   (cons (service hello-service-type)
         %base-services)))
