# Specification
# TODO(560f)

# Implementation

_logger_log() {
  local trace="$1"  
  local level="$2"
  local assertion="$3"
  local msg="$level | $assertion"
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

# … → Log
debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    _logger_log "true" "DEBUG" "$@";
  fi 
}

# … → Log
info() { _logger_log "false" "INFO " "$@"; }

# … → Log
objective() { _logger_log "false" "OBJECTIVE" "$@"; }

# … → Log
error() { _logger_log "false" "ERROR" "$@"; }

# … → Log
ok() { _logger_log "false" "OK" "$@"; }

# Message Param … → Error ∧ (exit 1)
failed_check() {
  local msg="$1"
  shift
  error "$msg" "$@"
  exit 1
}

# Value → Boolean
is_nat() {
  local value="$1"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi  
}

# Any → Maybe(Error ∧ (exit 1))
nat_check() {
  local value="$1"
  if ! is_nat "$value"; then
    failed_check "value does not represent a ℕ" "value=$value"
  fi
}

# Constructors
#   These functions build instances of Experiments.
#   Example:
#     experiment : A … → Experiment

# Interface
#   These functions use instances of Experiment
#   Example:
#     experiment_a : Experiment → A
#
#   Usage may fail
#   Example:
#     experiment_a :trace : Experiment → Result(A)
#   Result(A) ≡ Ok(A) | Error
#   knowing that:
#     error_trace : Error → List(String)

# Experiment :≡ ℕ
experiment() {
  nat_check "$1"
  echo "$1"
}

# value is a representation of an Experiment
is_experiment() {
  local value="$1"
  is_nat "$value"
}

# check if value is a representation of an Experiment
experiment_check() {
  if ! is_experiment "$1"; then failed_check "value is not an Experiment" "value=$1"; fi
}

# experiment_is_pair : Experiment → ℕ
# experiment_is_pair : Experiment "trace" → stdout=ℕ stderr="trace"
experiment_is_pair() {
  experiment_check "$1"
  local experiment="$1"
  debug "experiment=$1"
  debug "is experiment pair?"
  if (( experiment % 2 == 0 )); then
    echo $(( experiment / 2 ))
    return 0
  else
    return 1
  fi
}


experiment_is_pair "4"
