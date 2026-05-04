;; guix time-machine -C scheme/clocks/channels.scm -- deploy scheme/clocks/deploy/deploy-1.scm
(define-module (clocks deploy deploy-1))

(use-modules
 ((clocks constant) #:prefix cst:)
 (clocks os os-14)
 (gnu machine)
 (gnu machine ssh))

(define-public deploy-1
  (list
   (machine
    (operating-system os-14)
    (environment managed-host-environment-type)
    (configuration
     (machine-ssh-configuration
      (host-name "168.119.224.132")
      (system "x86_64-linux")
      (host-key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1eIi7Ct39Md2VXEfTWBXyttwmIpe9KohgCWhTyvN4j"))))))

deploy-1
