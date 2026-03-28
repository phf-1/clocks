;; Specification

;; [[id:34bd9436-f033-4395-b53d-eda7e3e327c2]] 
;; This module exports os.
;; os is an [[ref:6b498911-27ba-48b5-9115-a3744b5dc7e6][OS]] that extends [[ref:7f1cb335-753f-448b-9637-39c130ded682][init:os]] with the following services:
;;   [[ref:13542dc8-a522-48de-aed9-ea1b0b57a85a][postgresql]] 
;;   [[ref:29f62d83-9846-45f2-b102-12a83cf6e0b7][app]]
;;
;; and packages:
;;   [[ref:d7676b1e-5acf-43b0-b74b-39c593389010][postgresql-package]]
;;
;; TODO(cd22): services graph may be shown using guix system shepherd-graph

;; Implementation

(define-module (app vm prod os))

(use-modules
 ((gnu services)
  #:select
  (service))
 
 ((gnu services databases)
  #:select
  (postgresql-service-type
   postgresql-config-file))
 
 ((gnu packages databases)
  #:select
  (postgresql))
 
 ((gnu system)
  #:select
  (operating-system
   operating-system-packages
   operating-system-user-services))
 
 ((os init)
  #:select (os)
  #:prefix init:)
 
 ((app service)
  #:select
  (app-service-type
   app-configuration)))

(define postgresql-service
  (service
   postgresql-service-type
   (postgresql-configuration
    (postgresql postgresql)
    (config-file
     (postgresql-config-file
      (extra-config
       '(("listen_addresses" "localhost")
         ("max_connections" "50")
         ("shared_buffers" "64MB"))))))))

(define app-service
  (service
   app-service-type
   (app-configuration)))

(define packages
  (cons
   postgresql
   (operating-system-packages init:os)))

(define services
  (cons*
   postgresql-service
   app-service
   (operating-system-user-services init:os)))

(define os
  (operating-system
   (inherit init:os)
   (host-name "os")
   (packages packages)
   (services services)))

;; Interface

(export os)
