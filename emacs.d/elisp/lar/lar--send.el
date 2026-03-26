;;; lar--send.el --- Actor communication primitive -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Pierre-Henry FRÖHRING
;; Author: Pierre-Henry FRÖHRING contact@phfrohring.com
;; SPDX-License-Identifier: GPL-3.0-or-later
;; [[ref:10025816-10f9-4f9c-a010-55802b295348][specification]]

;;; Code:

(defun lar--send (actor msg)
  "Send MSG to ACTOR."
  (funcall actor msg))

(defun lar--send-msg (kw &optional params)
  (if params (cons kw params) kw))

(defun lar--mk (actor &rest params)
  "Send :mk message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :mk params)))

(defun lar--loc (actor &rest params)
  "Send :loc message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :loc params)))

(defun lar--ref (actor &rest params)
  "Send :ref message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :ref params)))

(defun lar--check (actor &rest params)
  "Send :check message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :check params)))

(defun lar--posint (actor &rest params)
  "Send :posint message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :posint params)))

(defun lar--keyword (actor &rest params)
  "Send :keyword message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :keyword params)))

(defun lar--list (actor &rest params)
  "Send :list message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :list params)))

(defun lar--unexpected (actor &rest params)
  "Send :unexpected message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :unexpected params)))

(defun lar--tag (actor &rest params)
  "Send :tag message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :tag params)))

(defun lar--id (actor &rest params)
  "Send :id message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :id params)))

(defun lar--start (actor &rest params)
  "Send :start message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :start params)))

(defun lar--stop (actor &rest params)
  "Send :stop message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :stop params)))

(defun lar--end (actor &rest params)
  "Send :end message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :end params)))

(defun lar--inverse (actor &rest params)
  "Send :inverse message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :inverse params)))

(defun lar--buffer (actor &rest params)
  "Send :buffer message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :buffer params)))

(defun lar--name (actor &rest params)
  "Send :name message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :name params)))

(defun lar--string (actor &rest params)
  "Send :string message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :string params)))

(defun lar--render (actor &rest params)
  "Send :string message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :render params)))

(defun lar--links (actor &rest params)
  "Send :links message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :links params)))

(defun lar--directory (actor &rest params)
  "Send :directory message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :directory params)))

(defun lar--executable (actor &rest params)
  "Send :executable message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :executable params)))

(defun lar--search (actor &rest params)
  "Send :search message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :search params)))

(defun lar--reset (actor &rest params)
  "Send :reset message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :reset params)))

(defun lar--display (actor &rest params)
  "Send :display message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :display params)))

(defun lar--add (actor &rest params)
  "Send :add message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :add params)))

(defun lar--clean (actor &rest params)
  "Send :clean message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :clean params)))

(defun lar--regex (actor &rest params)
  "Send :regex message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :regex params)))

(defun lar--rg (actor &rest params)
  "Send :rg message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :rg params)))

(defun lar--root (actor &rest params)
  "Send :root message to ACTOR with PARAMS."
  (lar--send actor (lar--send-msg :root params)))

(provide 'lar--send)
;;; lar--send.el ends here
