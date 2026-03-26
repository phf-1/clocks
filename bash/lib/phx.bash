if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Specification

# Implementation

phx_root() { echo "$ROOT/phoenix"; }
phx_priv() { echo "$(phx_root)/priv"; }
phx_static() { echo "$(phx_priv)/static"; }
phx_dev_port() { echo 4000; }
phx_test_port() { echo 4001; }
phx_prod_port() { echo 4002; }
phx_mode_to_port() {
  local mode="$1"
  mode_check "$mode"
  if [[ "$mode" == "$(mode_dev)" ]]; then phx_dev_port; fi
  if [[ "$mode" == "$(mode_test)" ]]; then phx_test_port; fi
  if [[ "$mode" == "$(mode_prod)" ]]; then phx_prod_port; fi
}
