if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

db_root() { echo "$ROOT/_postgresql"; }
db_dev_port() { echo 5432; }
db_test_port() { echo 5433; }
db_prod_port() { echo 5434; }
mapfile -t _DB_PORTS < <(
  db_dev_port
  db_test_port
  db_prod_port
)
db_port_check() {
  local port="$1"
  value_in_check "$port" "${_DB_PORTS[@]}"
}
db_mode_to_port() {
  local mode="$1"
  mode_check "$mode"
  if [[ "$mode" == "$(mode_dev)" ]]; then db_dev_port; fi
  if [[ "$mode" == "$(mode_test)" ]]; then db_test_port; fi
  if [[ "$mode" == "$(mode_prod)" ]]; then db_prod_port; fi
}
db_mode_to_url() {
  local mode="$1"
  mode_check "$mode"
  local port
  port="$(db_mode_to_port "$mode")"
  echo "ecto://postgres@localhost:${port}/clocks_${mode}"
}
db_mode_to_data() {
  local mode="$1"
  mode_check "$mode"
  echo "$(db_root)/${mode}/data"
}
db_mode_to_log() {
  local mode="$1"
  mode_check "$mode"
  echo "$(db_root)/${mode}/log"
}
