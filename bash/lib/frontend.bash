# Specification

# [[id:dc574829-4e8a-46cb-94c8-09ab64d85a1a]] 
# frontend : Frontend represents the frontend
# root : Directory
# version : [[ref:88356c79-513c-4651-b3b7-ccac82e11a68][Version]] 
# update : Version (updates the frontend version)
# dist : Url → [[ref:9f5eb7ae-fc62-4227-af9d-ffb0b93a9d9a][Distribution]] :≡
#   url ↦ build a distribution of the frontend that points to url
# clean : delete the distribution is any

# Implementation

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this file must be sourced, not executed." >&2
  exit 1
fi

# Interface

frontend_root() { echo "$_ROOT/frontend"; }

frontend_version() {
  echo "$(cd "$(frontend_root)"; git rev-parse --short HEAD)"
}

frontend_update() {
  (
    cd "$(frontend_root)"
    if ! git pull &>/dev/null; then
      failed_check "Could not update the frontend"
    fi
    if ! npm i &>/dev/null; then
      failed_check "Could not update frontend dependencies"
    fi
    frontend_version
  )
}

frontend_dist() {
  # TODO(67c2): url_check $1 
  local url="$1"  
  export VITE_API_BASE_URL="$url"
  (
    cd "$(frontend_root)"
    if ! npm run build &>/dev/null; then
      failed_check "could not build the frontend distribution"
    fi
  )  
  echo "$(frontend_root)/dist";
}

# TODO(57fa) 
frontend_clean() {
  # TODO(67c2): url_check $1 
  rm -rf "$(frontend_root)/dist"/*;
}
