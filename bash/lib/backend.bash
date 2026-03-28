if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Context

# [[id:0c0d4f2a-41da-40aa-9fd2-43f7d0a7fd4b][FrontendDistribution]] :≡ [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][Distribution]]


# Specification

# Implementation

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

# [[ref:0c0d4f2a-41da-40aa-9fd2-43f7d0a7fd4b][FrontendDistribution]] → [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][Distribution]]
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

