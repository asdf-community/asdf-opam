#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/ocaml/opam"
TOOL_NAME="opam"
TOOL_TEST="opam --version"

fail() {
  echo "asdf-${TOOL_NAME}: $*" >&2
  exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    awk '{print $2}' |
    sed 's|refs/tags/||; s/^v//' |
    grep '^[0-9]'
}

list_all_versions() {
  list_github_tags
}

latest_version() {
  list_all_versions | sort_versions | tail -n1 | xargs echo
}

resolve_version() {
  local version="$1"

  if [ "$version" = "latest" ]; then
    version="$(latest_version)"
  fi

  echo "$version"
}

detect_platform() {
  case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*) echo "linux" ;;
    openbsd*) echo "openbsd" ;;
    *) fail "Unsupported platform" ;;
  esac
}

detect_architecture() {
  case "$(uname -m)" in
    x86_64) echo "x86_64" ;;
    i686) echo "i686" ;;
    armv7l) echo "armhf" ;;
    arm | arm64 | aarch64) echo "arm64" ;;
    *) fail "Unsupported architecture" ;;
  esac
}

release_filename() {
  local version="$1"
  local architecture platform
  architecture="$(detect_architecture)"
  platform="$(detect_platform)"
  echo "${TOOL_NAME}-${version}-${architecture}-${platform}"
}

release_url() {
  local version="$1"
  local filename
  filename="$(release_filename "$version")"
  echo "${GH_REPO}/releases/download/${version}/${filename}"
}

download_release() {
  local version="$1"
  local filename="$2"
  local resolved_version url
  resolved_version="$(resolve_version "$version")"
  url="$(release_url "$resolved_version")"

  echo "Downloading ${TOOL_NAME} release ${resolved_version}..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" ||
    fail "Could not download ${url}"
  chmod +x "$filename" ||
    fail "Could not set execute permission on ${filename}"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="${3%/bin}/bin"
  local resolved_version downloaded_file

  if [ "$install_type" != "version" ]; then
    fail "asdf-${TOOL_NAME} supports release installs only"
  fi

  resolved_version="$(resolve_version "$version")"
  downloaded_file="$ASDF_DOWNLOAD_PATH/$(release_filename "$resolved_version")"

  (
    mkdir -p "$install_path"
    cp "$downloaded_file" "$install_path/$TOOL_NAME"
    chmod +x "$install_path/$TOOL_NAME"

    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/$tool_cmd" ||
      fail "Expected $install_path/$tool_cmd to be executable."

    echo "${TOOL_NAME} ${resolved_version} installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error occurred while installing ${TOOL_NAME} ${resolved_version}."
  )
}
