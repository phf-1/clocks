;; Specification

;; [[id:46f33030-5101-4dbb-86e6-44e542d9f0ba]] 
;; This module exports machine.
;; machine is a [[ref:a99835ae-90fb-4021-8d1b-a49f741c1152][Machine]] where to deploy [[ref:7f1cb335-753f-448b-9637-39c130ded682][os]].

;; Implementation

(define-module (app vm init machine))

(use-modules
 ((gnu machine)
  #:select
  (machine)
  #:prefix gnu:)

 ((gnu machine ssh)
  #:select
  (managed-host-environment-type
   machine-ssh-configuration))

 ((app vm init os)
  #:select
  (os)))

;; see: [[ref:aa625827-d060-4211-a1a9-8d97db13b3c5]]
(define %host-name "127.0.0.1")
(define %ssh-port 2222)
(define %host-key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzl+2oLrK7D6afUFd3UaFKr3LF5/f3E5AvBnFVpHYDp")

;; (define project-root
;;   (string-append (dirname (current-filename)) "/.."))

;; (define host-key
;;   (call-with-input-file
;;       (string-append project-root "/ssh/host_ed25519.pub")
;;     read-line))

;; Interface

(define-public machine
  (gnu:machine
   (environment managed-host-environment-type)
   (configuration
    (machine-ssh-configuration
     (host-name %host-name)
     (port %ssh-port)
     (host-key %host-key)
     (system "x86_64-linux")))
   (operating-system os)))
