if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# dir_check "something" ⇒ log an error and exit 1 if "something" is not a directory.
# …

# Context

ROOT_DIR="$(readlink -f "${BASH_SOURCE[0]%/*}/..")"
LIB_DIR="$ROOT_DIR/lib"

# shellcheck source=bash/lib/log.bash
source "$LIB_DIR/log.bash"

# Interface

dir_check() {
  if [[ ! -d "$1" ]]; then
    error "dir is not a directory" "dir=$1"
    exit 1
  fi
}

file_check() {
  if [[ ! -f "$1" ]]; then
    error "file is not a regular file." "file=$1"
    exit 1
  fi
}

value_in_check() {
  local value="$1"
  shift
  local allowed=("$@")

  for v in "${allowed[@]}"; do
    [[ "$value" == "$v" ]] && return 0
  done

  error "value not in allowed set" "value=$value" "allowed=${allowed[*]}"
  exit 1
}
