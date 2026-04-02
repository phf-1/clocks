# Specification

# [[id:be56746d-435f-44cb-83dd-bddb71c6a03e][app]]
#
# This module represents the application.
#
# repl : ∅ (Given a working db, installed frontend, then starts the repl)

# Implementation

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

_APP="$_ROOT/app"
_APP_TMP="$(mktemp -d --suffix '-app')"

# Interface

app_repl() {
  (cd "$(backend_root)" && iex --dbg pry -S mix phx.server)
}

# App → Name
app_name() {
  echo "clocks"
}

# Mode → Port
app_port() {
  mode_check "$1"
  local mode="$1"
  backend_port "$mode"
}

# Mode → Url
app_url() {
  mode_check "$1"
  local mode="$1"
  echo "http://localhost:$(app_port "$mode")/api"
}

# [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][Distribution]]
app_dist() {
  local mode
  mode=prod
  local url
  url="$(app_url "$mode")"
  backend_dist "$(frontend_dist "$url")"
}

# [[ref:4d0d3620-0e64-4095-9af9-34bf78e05509][Distribution]] → [[ref:65e6819a-31da-4ba2-a6cb-f1ee97c06020][Package]]
app_package() {
  dir_check "$1"
  local dist="$1"
  local app_tmp="$_APP_TMP/app"
  mkdir -p "$app_tmp"
  cp -f "$_APP/package.scm" "$app_tmp/"
  local package_tmp="$app_tmp/package.scm"
  sed -i "s|__DIST__|$dist|" "$package_tmp"
  if ! msg="$(guix build -q -L "$_APP_TMP" app)"; then
    failed_check "Cannot build package" "package=$package_tmp" "msg=$msg"
  fi
  echo "$package_tmp"
}

# [[id:65e6819a-31da-4ba2-a6cb-f1ee97c06020][Package]] → [[ref:c12b81b0-eeeb-46de-9c1e-26d5113cbfdd][Service]]
app_service() {
  file_check "$1"
  local package="$1"
  echo "$_APP/service.scm"
}

# [[ref:c12b81b0-eeeb-46de-9c1e-26d5113cbfdd][Service]] → [[ref:1690d23c-6cae-49f6-87ec-438dd153d1ae][OS]]
app_os() {
  file_check "$1"
  local service="$1"
  echo "$_APP/os.scm"
}

# [[ref:1690d23c-6cae-49f6-87ec-438dd153d1ae][OS]] → [[ref:de72f362-d3c5-4c64-aab7-59a3d427e470][Machine]]
app_machine() {
  file_check "$1"
  local os="$1"
  echo "$_APP/machine.scm"
}

# [[ref:de72f362-d3c5-4c64-aab7-59a3d427e470][m:Machine]] → m is deployed
app_deploy() {
  file_check "$1"
  local machine="$1"
  local deployment="$_APP_TMP/deployment.scm"
  cat <<EOF >"$deployment"
(use-modules ())
(list %machine)
EOF
  debug "deployment=$deployment"
  guix deploy -L "$package_d" "$deployment"
}
