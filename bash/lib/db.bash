# Specification

# [[id:54b11ca0-d89d-4940-8295-e63f1ca94546]]
#
# TODO(bc1e) 

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

source "${BASH_SOURCE[0]%/*}/fs.bash"
source "${BASH_SOURCE[0]%/*}/check.bash"
source "${BASH_SOURCE[0]%/*}/mode.bash"

_DB_DEV_PORT=5432
_DB_TEST_PORT=5433
_DB_PROD_PORT=5434

# List(Port)
mapfile -t _DB_PORTS < <(
  $_DB_DEV_PORT
  $_DB_TEST_PORT
  $_DB_PROD_PORT
)

# Interface

db_root() {
  echo "$(fs_root)/_postgresql";
}

db_dev_port() {
  echo $_DB_DEV_PORT;
}

db_test_port() {
  echo $_DB_TEST_PORT;
}

db_prod_port() {
  echo $_DB_PROD_PORT;
}

db_port_check() {
  value_in_check "$1" "${_DB_PORTS[@]}"
}

db_port() {
  mode_check "$1"
  local mode="$1"
  if [[ "$mode" == "dev" ]]; then db_dev_port;
  elif [[ "$mode" == "test" ]]; then db_test_port;
  elif [[ "$mode" == "prod" ]]; then db_prod_port;
  else failed_check "Unexpected mode" "mode=$mode"; fi
}

db_mode_to_url() {
  mode_check "$1"
  local mode="$1"
  local port
  port="$(db_port "$mode")"
  echo "ecto://postgres@localhost:${port}/clocks_${mode}"
}

db_mode_data() {
  mode_check "$1"
  local mode="$1"
  echo "$(db_root)/${mode}/data"
}

db_mode_log() {
  mode_check "$1"
  local mode="$1"
  echo "$(db_root)/${mode}/log"
}

db_init() {
  mode_check "$1"
  local mode="$1"
  DB_DATA="$(db_mode_data "$mode")"
  if [[ ! -f "${DB_DATA}/PG_VERSION" ]]; then
    mkdir -p "${DB_DATA}"
    initdb -D "${DB_DATA}" --auth=trust --username=postgres --encoding=UTF8
  fi  
}

db_start() {
  mode_check "$1"
  local mode="$1"
  ,db-init "$mode"
  DB_DATA="$(db_mode_data "$mode")"
  DB_LOG="$(db_mode_log "$mode")"
  DB_PORT="$(db_port "$mode")"
  DB_PARAMS="DB_DATA=$DB_DATA DB_LOG=$DB_LOG DB_PORT=$DB_PORT"
  if ! pg_ctl -D "${DB_DATA}" status >/dev/null 2>&1; then
    if pg_ctl -D "${DB_DATA}" -l "${DB_LOG}" -o "-p ${DB_PORT} -k /tmp" start; then
      :
    else
      error "Could not start PostgreSQL" "$DB_PARAMS"
      debug "Last 30 lines of the log:"
      tail -n 30 "${DB_LOG}" 2>/dev/null || true
      echo ""
      debug "Most common cause: stale process on port" "port=$DB_PORT"
      debug "Run this cmd once and try again" "cmd=pkill -9 -f postgres && rm -f ${DB_DATA}/postmaster.pid"
      exit 1
    fi
  fi
}

db_clean() {
  DBROOT="$(db_root)"
  rm -rf "$DBROOT"  
}
