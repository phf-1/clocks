# Specification

# [[id:51cbff0d-4f5b-4674-83b1-8b5358434ef2]]
#
# This module represents the backend i.e. the code that replies to the frontend requests.
#
# root : Directory
# dev_port : Port
# test_port : Port
# prod_port : Port
# port : Mode → Port
# update : ∅ (dependencies are fetched)
# frontend_dist : Directory where to install a [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]].
# dist : [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]] → [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][PhoenixDistribution]]
# install_frontend : [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]] → ∅
# init_db : [[ref:9498f31c-91da-4a26-85a7-e0fad70bedff][Mode]] → ∅ (Given an active db, then create the tables)
# migrate : [[ref:9498f31c-91da-4a26-85a7-e0fad70bedff][Mode]] → ∅ (Given an active and initialized db, then migrate the db)
# format : ∅ (Format the code of the backend)
# analyse : ∅ (Execute static analysis tools)
# test : ∅ (Execute all tests)
# test_by_id : String → ∅ (Execute the tests designated by this id)
# mode_url : Mode → Url (Where the backend is listening)
# clean : ∅ (Delete all generated files)

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

[[ -v _LIB_BACKEND ]] && return
_LIB_BACKEND=1

source "${BASH_SOURCE[0]%/*}/check.bash"
source "${BASH_SOURCE[0]%/*}/mode.bash"
source "${BASH_SOURCE[0]%/*}/db.bash"

_BACKEND="$(fs_root)/backend"
dir_check "$_BACKEND"

# Interface

backend_root() { echo "$_ROOT/backend"; }

backend_dev_port() { echo 4000; }

backend_test_port() { echo 4001; }

backend_prod_port() { echo 4002; }

backend_mode_port() {
  mode_check "$1"
  local mode="$1"
  if [[ "$mode" == "dev" ]]; then
    backend_dev_port
  elif [[ "$mode" == "test" ]]; then
    backend_test_port
  elif [[ "$mode" == "prod" ]]; then
    backend_prod_port
  else failed_check "Unexpected mode" "mode=$mode"; fi
}

backend_update() {
  (
    cd "$(backend_root)"
    mix local.hex --force --if-missing
    mix deps.get
  )
}

backend_frontend_dist() {
  echo "$(backend_root)/priv/static"
}

backend_install_frontend() {
  dir_check "$1"
  local frontend_dist="$1"
  if ! rsync -a --delete "$frontend_dist/" "$(backend_frontend_dist)/" &>/dev/null; then
    failed_check "Cannot install frontend dist in the backend"
  fi
}

backend_dist() {
  dir_check "$1"
  local frontend_dist="$1"
  backend_install_frontend "$frontend_dist"
  export MIX_ENV="prod"
  local root
  root="$(backend_root)"
  local path="$root/_build/$MIX_ENV/rel/dist"
  (
    cd "$root"
    if ! mix deps.get --only "$MIX_ENV" &>/dev/null; then
      failed_check "Could not fetch dependencies"
    fi
    if ! mix compile &>/dev/null; then
      failed_check "compilation failed"
    fi
    if ! mix assets.deploy &>/dev/null; then
      failed_check "assets.deploy failed"
    fi
    if ! mix phx.gen.release &>/dev/null; then
      failed_check "phx.gen.release failed"
    fi
    if ! mix release --overwrite --path "$path" &>/dev/null; then
      failed_check "release failed"
    fi
  )
  echo "$path"
}

backend_init_db() {
  mode_check "$1"
  local mode="$1"
  local DATABASE_URL="$(db_mode_url "$mode")"
  # TODO(abde): test that db is active
  MIX_ENV="$mode"
  (cd "$(backend_root)" && mix ecto.create)
}

backend_migrate() {
  mode_check "$1"
  local mode="$1"
  local DATABASE_URL="$(db_mode_url "$mode")"
  # TODO(abde): test that db is active
  MIX_ENV="$mode"
  (cd "$(backend_root)" && mix ecto.migrate)
}

backend_format() {
  (cd "$(backend_root)" && mix format)
}

backend_analyse() {
  backend_format
  (cd "$(backend_root)" && mix credo --strict)
  (cd "$(backend_root)" && mix dialyzer --format short)
  (cd "$(backend_root)" && mix sobelow --config)
}

backend_test_by_id() {
  (cd "$(backend_root)" && mix test --only "$1")
}

backend_test() {
  (cd "$(backend_root)" && mix test)
}

backend_clean() {
  (cd "$(backend_root)" && mix clean && rm -rf _build deps)
}

backend_mode_url() {
  mode_check "$1"
  local mode="$1"
  local port="$(backend_mode_port "$mode")"
  if [[ "$mode" == "dev" ]]; then
    echo "http://localhost:$port/api"
  elif [[ "$mode" == "test" ]]; then
    echo "http://localhost:$port/api"
  elif [[ "$mode" == "prod" ]]; then
    echo "http://localhost:$port/api"
  else failed_check "unexpected mode" "mode=$mode"; fi
}
