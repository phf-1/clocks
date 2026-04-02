# Specification

# [[id:54b11ca0-d89d-4940-8295-e63f1ca94546][db]]
#
# This modules represents the database.
#
# root : Directory
# dev_port : [[ref:bbabbbd6-cd92-44b3-91b7-095c979f7f45][Port]]
# test_port : Port
# prod_port : Port
# mode_port : [[ref:9498f31c-91da-4a26-85a7-e0fad70bedff][Mode]] → Port
# mode_url : Mode → Url
# mode_data : Mode → Directory
# mode_log : Mode → Directory
# init : Path (Initialize the db root directory)
# start : Mode → String (Given that the db directory has been initialized, then start the db, return params)
# clean : ∅ (Delete all db data)

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
_DB_PORTS=(
  $_DB_DEV_PORT
  $_DB_TEST_PORT
  $_DB_PROD_PORT
)

# Interface

db_root() {
  echo "$(fs_root)/_postgresql"
}

db_dev_port() {
  echo $_DB_DEV_PORT
}

db_test_port() {
  echo $_DB_TEST_PORT
}

db_prod_port() {
  echo $_DB_PROD_PORT
}

db_mode_port() {
  mode_check "$1"
  local mode="$1"
  if [[ "$mode" == "dev" ]]; then
    db_dev_port
  elif [[ "$mode" == "test" ]]; then
    db_test_port
  elif [[ "$mode" == "prod" ]]; then
    db_prod_port
  else failed_check "Unexpected mode" "mode=$mode"; fi
}

db_mode_url() {
  mode_check "$1"
  local mode="$1"
  local port
  port="$(db_mode_port "$mode")"
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
  local db_data="$(db_mode_data "$mode")"
  if [[ ! -f "${db_data}/PG_VERSION" ]]; then
    mkdir -p "${db_data}"
    initdb -D "${db_data}" --auth=trust --username=postgres --encoding=UTF8
  fi
  echo "$db_data"
}

db_start() {
  mode_check "$1"
  local mode="$1"
  local db_data="$(db_mode_data "$mode")"
  local db_log="$(db_mode_log "$mode")"
  local db_port="$(db_mode_port "$mode")"
  local db_params="DB_DATA=$db_data DB_LOG=$db_log DB_PORT=$db_port"
  if ! pg_ctl -D "${db_data}" status >/dev/null 2>&1; then
    if ! pg_ctl -D "${db_data}" -l "${db_log}" -o "-p ${db_port} -k /tmp" start; then
      debug "Last 30 lines of the log:"
      tail -n 30 "${db_log}" 2>/dev/null || true
      echo ""
      debug "Most common cause: stale process on port" "port=$db_port"
      debug "Run this cmd once and try again" "cmd=pkill -9 -f postgres && rm -f ${db_data}/postmaster.pid"
      failed_check "Could not start PostgreSQL" "$db_params"
    fi
  fi
  echo "$db_params"
}

db_clean() {
  rm -rf "$(db_root)"
}
