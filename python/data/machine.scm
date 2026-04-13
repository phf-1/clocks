(define-module (clocks machine))

__OS__
(define %host-name "__IP__")
(define %ssh-port __PORT__)
(define %host-key "__KEY__")

(use-modules
 (gnu machine)
 (gnu machine ssh))

(define-public clocks:machine
  (machine
   (environment managed-host-environment-type)
   (configuration
    (machine-ssh-configuration
     (host-name %host-name)
     (port %ssh-port)
     (host-key (string-join `("ssh-ed25519" ,%host-key) " "))
     (system "x86_64-linux")))
   (operating-system os)))

(list clocks:machine)
