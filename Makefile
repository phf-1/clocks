# [[id:b80c22c9-2eed-4eea-a469-136e7666ea96]]

# Each rule uses a single Bash instance.
# The Bash script uses strict mode.
# It is silent by default.
SHELL := bash
.SHELLFLAGS := -ceuo pipefail
MAKEFLAGS += --no-print-directory
.ONESHELL:
.SILENT:

# The directory where the Phoenix application lives.
PHOENIX=phoenix

# make dev-env LOCAL=(true|false)
#   build a reproducible development environment. If LOCAL=true, then do not use
#   external APIs like xAI. Secrets are read from .env.gpg.
#
# make dev-env
#  same as: make dev-env LOCAL=true
#
# make dev-env CMD="..."
#   like make dev-env, then execute: $CMD.
#
# make dev-env LOCAL=false CMD="..."
#   like: make dev-env LOCAL=false, then execute: $CMD.
.PHONY: dev-env
dev-env:
	if [[ -v GUIX_ENVIRONMENT ]]; then
	  echo "INFO | Development environment is active."
	else
	  # Secrets are read in-memory.
	  # default password is: 0000
	  if [[ -f .env.gpg ]]; then
	    set +xv
	    set -a
	    eval "$$(gpg --quiet --batch --yes --decrypt .env.gpg 2>/dev/null)"
	    set +a
	  fi

	  # Default values are provided to necessary variables are provided.
	  export LC_ALL=C.UTF-8
	  export LANG=C.UTF-8
	  : $${CMD:=bash --init-file bash/etc/bashrc -i}
	  : $${XAI_API_KEY:="sk-0000"}
	  : $${LOCAL:=true}
	  : $${MIX_ENV:=dev}
	  : $${SECRET_KEY_BASE:=""}

	  # see: https://github.com/erlang/otp/blob/f1944a13c33f7214d498270ed2f09f39152d6952/lib/public_key/src/pubkey_os_cacerts.erl#L221
	  guix time-machine -C scheme/app/env/channels.scm -- shell \
		     -C \
	             -W \
		     -S /usr/bin=bin \
		     -S /etc/ssl/certs/ca-certificates.crt=etc/ssl/certs/ca-certificates.crt \
		     -E ^XAI_API_KEY \
	             -E ^SECRET_KEY_BASE \
		     -E ^LC_ALL \
		     -E ^LANG \
		     -E ^LOCAL \
		     -E ^MIX_ENV \
		     -E ^TERM \
		     -E ^DISPLAY \
		     -E ^XAUTHORITY \
	             -E ^SSH_AUTH_SOCK \
	             --share=$$SSH_AUTH_SOCK \
		     --expose="${XAUTHORITY}" \
		     --expose=/tmp/.X11-unix \
		     --expose=/etc/guix \
		     --share=/tmp \
		     -N \
		     -m scheme/app/env/manifest.scm \
		     -- bash -c "source bash/etc/bash_profile; projectctl; $${CMD}"
	fi

