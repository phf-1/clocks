;; Specification

;; [[id:7f1cb335-753f-448b-9637-39c130ded682][OS]]
;;
;; An OS represents an operating system.
;;
;; TODO(7461)

;; Implementation

(define-module (app vm init os))

(use-modules
 (gnu system)
 (gnu system locale)
 (gnu system file-systems)
 (gnu system shadow)
 (gnu bootloader)
 (gnu bootloader grub)
 (gnu services)
 (gnu services base)
 (gnu services networking)
 (gnu services ssh)
 (gnu packages base)
 (guix gexp)
 (app env constant))

;; see: [[ref:317882b2-8907-4bda-89ed-a1d60793ddc3]]

(define %user "root")
(define %host-name "init")
(define %root-pub-key dev-public-key-path)
(define %store-pub-key "/etc/guix/signing-key.pub")

;; The app user account is responsible for the applications.
;; (define %user-account "app")
;; (define app-user
;;   (user-account
;;    (name %user-account)
;;    (group "users")))


;; The system account is responsible for everything else, like system upgrades.
;; (define %system-account "system")
;; (define system-user
;;   (user-account
;;    (name %system-account)
;;    (group "system")
;;    (system? #t)))

;; For the system account to operate, it needs to be added to the sudoers file.
;; (define sudoers
;;   (plain-file
;;    "sudoers"
;;    (string-append
;;     (plain-file-content %sudoers-specification)
;;     (format #f "~a ALL = NOPASSWD: ALL~%" %system-account))))

;; The VM listens for SSH connexions on port 22. It is only possible to connect
;; through ed25519 pub/key pairs using the declared accounts.
(define %ssh-port 22)
(define ssh-service
  (service
   openssh-service-type
   (openssh-configuration
    (port-number %ssh-port)
    ;; (permit-root-login 'prohibit-password)
    (permit-root-login #t)
    (allow-empty-passwords? #f)
    (password-authentication? #f)
    (generate-host-keys? #t)
    (authorized-keys
     `((,%user ,(local-file %root-pub-key)))))))


;; For this OS to be deployed to using `guix deploy', it needs to have this host Guix
;; daemon signing key in order to accept build artifacts.
(define init-base-services
  (modify-services %base-services
                   (guix-service-type config =>
                                      (guix-configuration
                                       (inherit config)
                                       (authorized-keys
                                        (append (list (local-file %store-pub-key))
                                                %default-authorized-guix-keys))))))

;; DHCP
(define dhcp-service
  (service
   dhcpcd-service-type
   (dhcpcd-configuration)))

;; Services

(define services
  (cons*
   dhcp-service
   ssh-service
   init-base-services))

;; Interface

(define-public os
  (operating-system
   (host-name %host-name)
   (timezone "Etc/UTC")
   (locale "C.UTF-8")
   (locale-libcs (list glibc))
   (locale-definitions
    (list
     (locale-definition (source "C") (name "C.UTF-8"))))
   (bootloader
    (bootloader-configuration
     (bootloader grub-bootloader)
     (targets '("/dev/vda"))
     (terminal-outputs '(console))))
   (file-systems
    (cons (file-system
           (mount-point "/")
           (device "/dev/vda1")
           (type "ext4"))
          %base-file-systems))

   ;; (groups (new-group ))

   ;; (users
   ;;  (cons*
   ;;   app-user
   ;;   system-user
   ;;   %base-user-accounts))

   (services services)))

;; So that 'guix image /…/os.scm' works
os
