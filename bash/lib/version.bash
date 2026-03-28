if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# https://hexdocs.pm/elixir/Version.html

# Implementation

# major, minor, patch : ℕ → Version
version() {
  nat_check "$1"
  nat_check "$2"
  nat_check "$3"
  echo "v$1.$2.$3"
}

# Any → Boolean
is_version() {
  if [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    return 0
  else
    return 1
  fi
}

# x : Any → is_version(x) = false → Error
version_check() {
  local value="$1"
  if ! is_version "$value"; then
    failed_check "value is not a representation of a Version" "value=$value"
  fi
}

# Version → Commit | Error ∧ (exit 1)
version_to_commit() {
  version_check "$1"
  local vsn="$1"
  commit=$(git rev-parse "${vsn}^{commit}" 2>/dev/null || echo "")
  [[ -z "$commit" ]] && { failed_check "vsn is not associated to a commit" "vsn=$vsn"; }
  echo "$commit"
}
