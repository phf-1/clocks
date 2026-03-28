# Specification

# c : Commit represents a [[ref:8d611509-d83d-463a-add8-36e862c83f95][commit]]
# is? : Any → Boolean
# check : Any → Maybe(Error ∧ (exit 1))

# Implementation

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Interface

is_commit() {
  if git rev-parse -q --verify "$1" >/dev/null; then return 0; else return 1; fi
}

commit_check() {
  local value="$1"
  if ! is_commit "$value"; then
    failed_check "value is not a representation of a Commit" "value=$value"
  fi
}
