if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# https://hexdocs.pm/elixir/Version.html

# Implementation

is_version() {
  local vsn="$1"
  if [[ "$vsn" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    return 0
  else
    return 1
  fi
}
version_check() {
  local vsn="$1"
  if ! is_version "$vsn"; then
    failed_check "vsn is not a Version" "vsn=$vsn"
  fi
}
version_to_commit() {
  local vsn="$1"
  version_check "$vsn"
  git rev-parse --short "${vsn}^{commit}" 2>/dev/null || echo ""
}
