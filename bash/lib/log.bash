if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Logging library.
#   info "something"                ⇒ INFO | something
#   id=2 info "id is even" "id=$id" ⇒ INFO | id is even | id=2

# Context

_logger_log() {
  local level="$1"
  local msg="$2"
  shift 2
  if [[ $# -eq 0 ]]; then
    echo "$level | $msg"
  else
    local IFS=' | '
    echo "$level | $msg | $*"
  fi
}

# Interface

debug() { _logger_log "DEBUG" "$@"; }
info() { _logger_log "INFO " "$@"; }
error() { _logger_log "ERROR" "$@"; }
ok() { _logger_log "OK" "$@"; }
