# Specification

# [[id:9498f31c-91da-4a26-85a7-e0fad70bedff][Mode]]
#
# m : Mode represents the category of users using the application
# dev means developers
# test means automated systems for testing purposes
# prod means paying clients

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

_MODES=(dev test prod)

# Interface

mode_check() {
  value_in_check "$1" "${_MODES[@]}"
}
