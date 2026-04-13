;; [[id:865ae034-b9c2-4c72-a4c3-dbf4877ed4f5][os-15]]
;;
;; Minimal OS to initialize a Hetzner VPS: build the disk image then boot the VPS
;; from it.

(define-module (clocks os os-15))

(use-modules
 ((clocks channels) #:prefix ch:)
 ((clocks constant) #:prefix cst:)
 (gnu packages base)
 (gnu packages ssh)
 (gnu services base)
 (gnu services networking)
 (gnu services rsync)
 (gnu services ssh)
 (gnu system)
 (gnu packages rsync)
 (gnu system locale)
 (gnu)
 (guix gexp))

(define-public os-15
  (operating-system
   (host-name "os-15")
   (timezone "Etc/UTC")
   (keyboard-layout (keyboard-layout "fr"))

   (locale "C.UTF-8")
   (locale-libcs (list glibc))
   (locale-definitions (list (locale-definition (source "C") (name "C.UTF-8"))))

   ;; begin Hetzner conventions
   (bootloader
    (bootloader-configuration
     (bootloader grub-bootloader)
     (targets '("/dev/sda"))
     (terminal-outputs '(console))
     (keyboard-layout keyboard-layout)))
   (file-systems
    (cons (file-system
           (device "/dev/sda1")
           (mount-point "/")
           (type "ext4"))
          %base-file-systems))
   ;; end

   (packages (cons rsync %base-packages))

   (services
    (cons*
     (service dhcpcd-service-type
              (dhcpcd-configuration
               (static '("domain_name_servers=1.1.1.1"))))

     (service openssh-service-type
              (openssh-configuration
               (permit-root-login 'prohibit-password)
               (authorized-keys
                `(("root" ,(local-file cst:dev-public-key-path))))))

     (service rsync-service-type)

     (modify-services %base-services
                      (guix-service-type
                       config =>
                       (guix-configuration
                        (inherit config)
                        (channels ch:channels)
                        (authorized-keys
                         (cons (local-file "/etc/guix/signing-key.pub")
                               (guix-configuration-authorized-keys config))))))))))

os-15
