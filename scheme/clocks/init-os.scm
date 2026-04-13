;; [[id:7f1cb335-753f-448b-9637-39c130ded682][InitOS]]
;;
;; This module represents the initial OS, the one we get to install on a fresh
;; VPS. Then, it can be used as a target for deploying applications to. So, it is
;; minimal in nature, with just enough code to allow deployment.

(define-module (clocks init-os))

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
 (gnu packages emacs)
 (gnu packages guile)
 (gnu packages emacs-xyz)
 (gnu services guix)
 (gnu home)
 (guix gexp)
 ((clocks constant) #:prefix cst:))

;; A [[ref:38345dba-d72f-49b6-9c0e-1bade9e9677a][GuixSystem]] can be viewed as a network of services ([[ref:e2dba26b-b5a5-426f-82a0-a7f0772c2c69][ServicesDag]]).
(define services '())

;; To send/receive messages from/to the network, the machine gets an Ip address using
;; a DHCP service.
(define dhcp-service
  (service
   dhcpcd-service-type
   (dhcpcd-configuration)))
(set! services (cons dhcp-service services))

;; root can connect to the machine using an ssh connection. Variables names starting
;; with % are targets to scripts. See: [[ref:317882b2-8907-4bda-89ed-a1d60793ddc3]]
(define %user "root")
(define %root-pub-key cst:dev-public-key-path)
(define %ssh-port 22)
(define ssh-service
  (service
   openssh-service-type
   (openssh-configuration
    (port-number %ssh-port)
    (permit-root-login 'prohibit-password)
    (allow-empty-passwords? #f)
    (password-authentication? #f)
    (generate-host-keys? #t)
    (authorized-keys
     `((,%user ,(local-file %root-pub-key)))))))
(set! services (cons ssh-service services))

;; If root is connected, then it has basic tools.
(define root-home
  (home-environment
   (packages
    (list
     emacs-minimal
     guile-3.0
     emacs-geiser
     emacs-geiser-guile
     emacs-guix
     emacs-paredit
     ))))

;; Users' homes are defined
(define home-service
  (service guix-home-service-type
           `(("root" ,root-home))))
(set! services (cons home-service services))

;; For this system to accept to be deployed to, it needs to trust the programs it
;; receives from the emitter ([[ref:d78940d6-33a0-4235-b094-9fa13dc27506][GuixDeployment]]). So, it trusts the current machine.
;; TODO(b1e3): use guix-extension
(define %store-pub-key cst:store-public-key)
(define init-base-services
  (modify-services
   %base-services
   (guix-service-type config =>
                      (guix-configuration
                       (inherit config)
                       (authorized-keys
                        (append (list (local-file %store-pub-key))
                                %default-authorized-guix-keys))))))
(set! services (append init-base-services services))

;; Finally, the os is fully specified
(define %host-name "init")
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
   (services services)))

;; So that 'guix image /…/os.scm' works
os
