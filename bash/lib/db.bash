if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

# Path
db_root() {
  echo "$_ROOT/_postgresql";
}

# Port
db_dev_port() {
  echo 5432;
}

# Port
db_test_port() {
  echo 5433;
}

# Port
db_prod_port() {
  echo 5434;
}

# List(Port)
mapfile -t _DB_PORTS < <(
  db_dev_port
  db_test_port
  db_prod_port
)

# Any → Maybe(Error ∧ (exit 1))
db_port_check() {
  value_in_check "$1" "${_DB_PORTS[@]}"
}

# Mode → Port
db_port() {
  mode_check "$1"
  local mode="$1"
  if [[ "$mode" == "dev" ]]; then db_dev_port;
  elif [[ "$mode" == "test" ]]; then db_test_port;
  elif [[ "$mode" == "prod" ]]; then db_prod_port;
  else failed_check "Unexpected mode" "mode=$mode"; fi
}

# Mode → Url
db_mode_to_url() {
  mode_check "$1"
  local mode="$1"
  local port
  port="$(db_port "$mode")"
  echo "ecto://postgres@localhost:${port}/clocks_${mode}"
}

# Mode → Path
db_mode_to_data() {
  mode_check "$1"
  local mode="$1"
  echo "$(db_root)/${mode}/data"
}

# Mode → Path
db_mode_to_log() {
  mode_check "$1"
  local mode="$1"
  echo "$(db_root)/${mode}/log"
}
