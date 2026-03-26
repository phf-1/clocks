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

failed_check() {
  local msg="$1"
  shift
  error "$msg" "$@"
  exit 1
}

dir_check() {
  if [[ ! -d "$1" ]]; then
    failed_check "dir is not a directory" "dir=$1"
  fi
}

file_check() {
  if [[ ! -f "$1" ]]; then
    failed_check "file is not a regular file." "file=$1"
  fi
}

exist_check() {
  if [[ ! -e "$1" ]]; then
    failed_check "file does not exist" "file=$1"
  fi
}

value_in_check() {
  local value="$1"
  shift
  local allowed=("$@")

  for v in "${allowed[@]}"; do
    [[ "$value" == "$v" ]] && return 0
  done

  failed_check "value not in allowed set" "value=$value" "allowed=${allowed[*]}"
}

nat_check() {
  if [[ ! "$1" =~ ^[0-9]+$ ]]; then
    failed_check "value does not represent a ℕ" "value=$value"
  fi
}

cmd_check() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    failed_check "cmd is missing" "cmd=$cmd"
  fi
}

file_in_dir_pred() {
  local file
  file="$(realpath "$1")"
  if [[ ! -e "$file" ]]; then return 1; fi
  local dir
  dir="$(realpath "$2")"
  if [[ ! -d "$dir" ]]; then return 1; fi
  if [[ "$file" == "$dir/"* ]]; then return 0; else return 1; fi
}

file_in_dir_check() {
  local file
  file="$(realpath "$1")"
  exist_check "$file"
  local dir
  dir="$(realpath "$2")"
  dir_check "$dir"
  if ! file_in_dir_pred "$file" "$dir"; then
    failed_check "file ∉ dir" "file=$file" "dir=$dir"
  fi
}
