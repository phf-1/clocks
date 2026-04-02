# Specification

# Logging library
#   info "n is even" ↦ stdout += "INFO | n is even\n"
#   info "n is even" "n=$n" ↦ stdout += "INFO | n is even | n=2\n"
#   error …
#   objective …
#   error …
#   ok …
#   DEBUG=true; debug "n is even" ↦ stderr += "DEBUG | f | n is even\n"
#
# log_example_double() {
#   local x=$1
#   debug "x=$x"
#   echo $(( x * 2 ))
# }
#
# log_example() {
#   local a="$1"
#   debug "a=$a"
#   local x
#   # DEBUG=false
#   x="$(log_example_double $a)"
#   # DEBUG=true
#   debug "x=$x"
#   local y
#   y=$(( x * 2 ))
#   debug "y=$y"
#   echo $(( y + 1 ))
# }

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

_logger_log() {
  local trace="$1"
  local level="$2"
  local assertion="${3:-}"
  local msg
  if [[ -z "$assertion" ]]; then
    msg="$level"
  else
    msg="$level | $assertion"
  fi
  shift 3
  if [[ $# -gt 0 ]]; then
    local IFS=' | '
    msg="$msg | $*"
  fi
  if [[ "$trace" == "true" ]]; then
    echo "$msg" 1>&2
  else
    echo "$msg"
  fi
}

# Interface

debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    local caller="${FUNCNAME[1]:-top-level}"
    _logger_log "true" "DEBUG" "$caller" "${@:-}"
  fi
}

info() { _logger_log "false" "INFO     " "${@:-}"; }

objective() { _logger_log "false" "OBJECTIVE" "${@:-}"; }

error() { _logger_log "true" "ERROR    " "${@:-}"; }

ok() { _logger_log "false" "OK       " "${@:-}"; }

todo() { _logger_log "false" "TODO     " "${@:-}"; }
