# Specification

# [[id:eb1125c2-ffee-4d80-bff5-263f5e4f6010]]
#
# This module provides all Bash interfaces.

# Implementation

_LIB="${BASH_SOURCE[0]%/*}/lib"

# Interface

# shellcheck source=bash/lib/log.bash
source "$_LIB/log.bash"

# shellcheck source=bash/lib/check.bash
source "$_LIB/check.bash"

# shellcheck source=bash/lib/bash.bash
source "$_LIB/bash.bash"

# shellcheck source=bash/lib/scheme.bash
source "$_LIB/scheme.bash"

# shellcheck source=bash/lib/emacs.bash
source "$_LIB/emacs.bash"

# shellcheck source=bash/lib/mode.bash
source "$_LIB/mode.bash"

# shellcheck source=bash/lib/frontend.bash
source "$_LIB/frontend.bash"

# shellcheck source=bash/lib/db.bash
source "$_LIB/db.bash"

# shellcheck source=bash/lib/backend.bash
source "$_LIB/backend.bash"

# shellcheck source=bash/lib/version.bash
source "$_LIB/version.bash"

# shellcheck source=bash/lib/ip.bash
source "$_LIB/ip.bash"

# shellcheck source=bash/lib/port.bash
source "$_LIB/port.bash"

# shellcheck source=bash/lib/address.bash
source "$_LIB/address.bash"

# shellcheck source=bash/lib/os.bash
source "$_LIB/os.bash"

# shellcheck source=bash/lib/image.bash
source "$_LIB/image.bash"

# shellcheck source=bash/lib/machine.bash
source "$_LIB/machine.bash"

# shellcheck source=bash/lib/vm.bash
source "$_LIB/vm.bash"

# shellcheck source=bash/lib/commit.bash
source "$_LIB/commit.bash"

# TODO(73c1)
# shellcheck source=bash/lib/package.bash
# source "$_LIB/package.bash"

# shellcheck source=bash/lib/app.bash
source "$_LIB/app.bash"
