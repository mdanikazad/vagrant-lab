#!/usr/bin/env bash
#
# Install the standalone Docker Compose v2 binary.
#
# The "docker-compose-plugin" package installed by install-docker.sh provides
# the "docker compose" command (the modern, plugin-based interface). This
# script additionally installs the standalone "docker-compose" binary into
# /usr/local/bin so scripts and tutorials that still call the legacy
# hyphenated command keep working.
#
# Usage:
#   sudo ./scripts/install-docker-compose.sh
#
# Pin a specific version with COMPOSE_VERSION, e.g. COMPOSE_VERSION=v2.29.7.
#
# The script is idempotent and safe to run from the Vagrant shell provisioner.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

readonly COMPOSE_LATEST_URL="https://github.com/docker/compose/releases/latest/download"
readonly COMPOSE_RELEASE_URL="https://github.com/docker/compose/releases/download"
readonly INSTALL_PATH="/usr/local/bin/docker-compose"
readonly COMPOSE_VERSION="${COMPOSE_VERSION:-latest}"

# Temporary download target. Kept global so the cleanup trap can always
# resolve it, even after the installing function has returned.
TEMP_BINARY=""

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

log() {
  printf '\n==> %s\n' "$1"
}

info() {
  printf '    %s\n' "$1"
}

warn() {
  printf 'WARNING: %s\n' "$1" >&2
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

cleanup() {
  if [[ -n "${TEMP_BINARY}" && -f "${TEMP_BINARY}" ]]; then
    rm -f "${TEMP_BINARY}"
  fi
}

# ---------------------------------------------------------------------------
# Environment helpers
# ---------------------------------------------------------------------------

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "This script must be run as root. Try: sudo $0"
  fi
}

require_commands() {
  local command_name
  for command_name in curl sha256sum install; do
    command -v "${command_name}" >/dev/null 2>&1 \
      || die "Required command not found: ${command_name}"
  done
}

# Map the Debian/Ubuntu architecture onto the name used by the Compose
# release assets (aarch64 for arm64, x86_64 for amd64).
resolve_release_arch() {
  local architecture
  architecture="$(dpkg --print-architecture)"

  case "${architecture}" in
    arm64) echo "aarch64" ;;
    amd64) echo "x86_64" ;;
    *) die "Unsupported architecture: ${architecture}" ;;
  esac
}

# Base URL for the release assets, either "latest" or a pinned tag.
release_base_url() {
  local version="${1}"

  if [[ "${version}" == "latest" ]]; then
    echo "${COMPOSE_LATEST_URL}"
  else
    echo "${COMPOSE_RELEASE_URL}/${version}"
  fi
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

download_compose() {
  local binary_path="${1}"
  local arch="${2}"
  local version="${3}"
  local download_url

  download_url="$(release_base_url "${version}")/docker-compose-linux-${arch}"

  info "Downloading ${download_url}"
  curl -fsSL --retry 3 --retry-delay 2 "${download_url}" -o "${binary_path}"
}

verify_checksum() {
  local binary_path="${1}"
  local arch="${2}"
  local version="${3}"
  local expected actual

  if ! expected="$(curl -fsSL --retry 3 "$(release_base_url "${version}")/docker-compose-linux-${arch}.sha256" 2>/dev/null)"; then
    warn "Could not download the checksum file, skipping verification"
    return 0
  fi

  # The checksum file contains "<hash> *docker-compose-linux-<arch>".
  expected="${expected%% *}"
  expected="${expected%%$'\n'*}"

  if [[ -z "${expected}" ]]; then
    warn "Checksum file was empty, skipping verification"
    return 0
  fi

  actual="$(sha256sum "${binary_path}" | awk '{print $1}')"

  if [[ "${actual}" != "${expected}" ]]; then
    die "Checksum mismatch for the downloaded Compose binary (expected ${expected}, got ${actual})."
  fi

  info "Checksum verified"
}

install_compose() {
  local arch

  arch="$(resolve_release_arch)"
  TEMP_BINARY="$(mktemp)"

  log "Installing Docker Compose ${COMPOSE_VERSION} (${arch})"
  download_compose "${TEMP_BINARY}" "${arch}" "${COMPOSE_VERSION}"
  verify_checksum "${TEMP_BINARY}" "${arch}" "${COMPOSE_VERSION}"

  install -m 0755 "${TEMP_BINARY}" "${INSTALL_PATH}"
  info "Installed to ${INSTALL_PATH}"
}

verify_installation() {
  log "Verifying the installation"

  command -v docker-compose >/dev/null 2>&1 \
    || die "docker-compose is not on PATH"

  docker-compose version
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

main() {
  trap cleanup EXIT

  require_root
  require_commands

  install_compose
  verify_installation

  log "Docker Compose installation complete"
}

main "$@"
