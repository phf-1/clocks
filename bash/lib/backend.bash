# Specification

# [[id:51cbff0d-4f5b-4674-83b1-8b5358434ef2]]
#
# TODO(17af): description
#
# TODO(6688): interface 

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Interface

# Path
backend_root() { echo "$_ROOT/phoenix"; }

# Port
backend_dev_port() { echo 4000; }

# Port
backend_test_port() { echo 4001; }

# Port
backend_prod_port() { echo 4002; }

# Mode → Port
backend_port() {
  mode_check "$1"
  local mode="$1"
  if [[ "$mode" == "dev" ]]; then backend_dev_port;
  elif [[ "$mode" == "test" ]]; then backend_test_port;
  elif [[ "$mode" == "prod" ]]; then backend_prod_port;
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

#  [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][FrontendDistribution]] → [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][Distribution]]
backend_dist() {
  dir_check "$1"
  local frontend_dist="$1"
  if ! rsync -a --delete "$frontend_dist/" "$(backend_frontend_dist)/" &>/dev/null; then
    failed_check "Cannot install frontend dist in the backend"
  fi
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
  MODE="${1:-dev}"
  mode_check "$MODE"
  ,db-start "$MODE"
  DATABASE_URL="$(db_mode_to_url "$MODE")"
  export DATABASE_URL
  export MIX_ENV="$MODE"
  (cd "$(backend_root)" && mix ecto.create)  
}

backend_migrate() {
  mode_check "$1"  
  MODE="$1"
  ,backend-init-db "$MODE"
  DATABASE_URL="$(db_mode_to_url "$MODE")"
  export DATABASE_URL
  export MIX_ENV="$MODE"
  (cd "$(backend_root)" && mix ecto.migrate)  
}

backend_format() {
  (cd "$(backend_root)" && mix format)  
}

backend_credo() {
  (cd "$(backend_root)" && mix credo --strict)
}

backend_dialyser() {
    (cd "$(backend_root)" && mix dialyzer --format short)
}

backend_soblow() {
  (cd "$(backend_root)" && mix sobelow --config)
}

backend_analyse() {
  backend_format
  backend_credo
  backend_dialyzer
  backend_security
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
