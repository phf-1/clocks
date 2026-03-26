;; Specification

;; [[id:f4be9e33-ac98-4deb-9669-eb32223ceecc]] 
;; This module exports machine.
;; machine is a [[ref:a99835ae-90fb-4021-8d1b-a49f741c1152][Machine]] where to run [[ref:34bd9436-f033-4395-b53d-eda7e3e327c2][os]].

;; Implementation

(define-module (app vm dev machine))

;;;;;;;;;;;;;;;;
;; configuration
;;
;;   variables are named like this so that they can be parsed.
;;   var :≡ "(define %" name " " value ")"

(define %host-name "127.0.0.1")
(define %ssh-port 2222) ; TODO(d0e4): configurable? 

(use-modules
 ((gnu machine)
  #:select
  (machine))

 ((gnu machine ssh)
  #:select
  (managed-host-environment-type
   machine-ssh-configuration))

 ((app vm dev os)
  #:select
  (os))

  ((app env constant)
  #:select
  (dev-public-key-path)))

(define project-root
  (string-append (dirname (current-filename)) "/.."))

(define host-key
  (call-with-input-file
      (string-append project-root "/ssh/host_ed25519.pub")
    read-line))

(define machine
  (machine
   (environment managed-host-environment-type)
   (configuration
    (machine-ssh-configuration
     (host-name %host-name)
     (port %ssh-port)
     (host-key host-key)
     (system "x86_64-linux")))
   (operating-system os)))

;; Interface

(export machine)
