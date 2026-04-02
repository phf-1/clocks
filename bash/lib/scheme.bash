# Specification

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

source "${BASH_SOURCE[0]%/*}/fs.bash"
source "${BASH_SOURCE[0]%/*}/check.bash"

_SCHEME="$(fs_root)/scheme"
dir_check "$_SCHEME"

# Interface

scheme_root() {
  echo "$_SCHEME"
}

scheme_manifest() {
  echo "$_SCHEME/app/env/manifest.scm"
}

scheme_channels() {
  echo "$_SCHEME/app/env/channels.scm"
}
