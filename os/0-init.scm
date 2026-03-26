(use-modules
 (gnu)
 (gnu system locale))

(use-service-modules networking ssh)
(use-package-modules ssh base)

;;;;;;;;;;;;;;;;
;; configuration
;;
;;   variables are named like this so that they can be parsed.
;;   var :≡ "(define %" name " " value ")"

(define %ssh-port 22)

(operating-system
 (host-name "init-os")
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
 (users
  (cons (user-account
         (name "clocks")
         (group "users")
         (supplementary-groups '("wheel"))
         (home-directory "/home/clocks"))
        %base-user-accounts))
 (services
  (append
   (list
    (service
     dhcpcd-service-type
     (dhcpcd-configuration))
    (service
     openssh-service-type
     (openssh-configuration
      (port-number %ssh-port)
      (permit-root-login #f)
      (allow-empty-passwords? #f)
      (password-authentication? #f)
      (authorized-keys
       `(("clocks" ,(local-file "../ssh/ed25519.pub")))))))
   %base-services)))
