#!/usr/bin/env bash
#
# Install Docker Engine + Docker Compose on Ubuntu.
#
# Safe to run both manually and from the Vagrant shell provisioner:
#   sudo ./scripts/install-docker.sh
#
# The script is idempotent: re-running it leaves an already-installed
# Docker untouched apart from refreshing the packages and adding the
# "docker" group membership for non-root users.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

readonly DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
readonly DOCKER_SOURCE_LIST="/etc/apt/sources.list.d/docker.list"
readonly DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
readonly DOCKER_PACKAGES=(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)
readonly DOCKER_GROUP="docker"

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

log() {
  printf '\n==> %s\n' "$1"
}

info() {
  printf '    %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Environment helpers
# ---------------------------------------------------------------------------

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "This script must be run as root. Try: sudo $0"
  fi
}

require_ubuntu() {
  local id=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    id="$(. /etc/os-release && echo "${ID:-}")"
  fi

  if [[ "${id}" != "ubuntu" ]]; then
    die "This script only supports Ubuntu (detected: ${id:-unknown})."
  fi
}

# apt and dpkg must never prompt: the Vagrant shell provisioner runs without a
# TTY, so an interactive debconf prompt would either hang or fail the build.
export DEBIAN_FRONTEND=noninteractive
# needrestart would otherwise try to restart services and print warnings
# mid-install; "a" = automatic restart, "1" = suspend the service check.
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

# Keep dpkg from asking questions about conffiles or restarting services.
# --force-confdef / --force-confold keep the existing conffile when it was
# modified locally, which is what an unattended install should do.
readonly DPKG_OPTIONS=(
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

apt_install() {
  apt-get "${DPKG_OPTIONS[@]}" install -y "$@"
}

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

update_apt_packages() {
  log "Updating apt package lists"
  apt-get update

  log "Upgrading installed apt packages"
  apt-get "${DPKG_OPTIONS[@]}" upgrade -y
}

install_prerequisites() {
  log "Installing Docker repository prerequisites"
  apt_install ca-certificates curl gnupg
}

configure_docker_repository() {
  local architecture codename

  architecture="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"

  [[ -n "${codename}" ]] || die "Could not determine the Ubuntu codename."

  log "Adding the Docker apt repository for ${codename}/${architecture}"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "${DOCKER_REPO_URL}/gpg" -o "${DOCKER_KEYRING}"
  chmod a+r "${DOCKER_KEYRING}"

  printf 'deb [arch=%s signed-by=%s] %s %s stable\n' \
    "${architecture}" "${DOCKER_KEYRING}" "${DOCKER_REPO_URL}" "${codename}" \
    > "${DOCKER_SOURCE_LIST}"

  apt-get update
}

install_docker() {
  log "Installing Docker Engine, Buildx, and the Compose plugin"
  apt_install "${DOCKER_PACKAGES[@]}"
}

start_and_enable_docker() {
  log "Starting Docker"
  systemctl enable --now docker
}

# Add the "docker" group to the given user so they can talk to the daemon
# without sudo. Membership only takes effect for *new* login sessions.
add_user_to_docker_group() {
  local username="${1:-}"

  if [[ -z "${username}" ]]; then
    return 0
  fi

  if ! id -u "${username}" >/dev/null 2>&1; then
    info "User '${username}' does not exist, skipping group setup"
    return 0
  fi

  if id -nG "${username}" | tr ' ' '\n' | grep -qx "${DOCKER_GROUP}"; then
    info "User '${username}' is already a member of the '${DOCKER_GROUP}' group"
    return 0
  fi

  log "Adding user '${username}' to the '${DOCKER_GROUP}' group"
  usermod -aG "${DOCKER_GROUP}" "${username}"
  info "Log out and back in (or run 'newgrp ${DOCKER_GROUP}') for it to take effect"
}

verify_installation() {
  log "Verifying the installation"

  systemctl is-active --quiet docker || die "Docker is not active"
  systemctl is-enabled --quiet docker || die "Docker is not enabled"

  docker --version
  docker compose version
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

main() {
  require_root
  require_ubuntu

  update_apt_packages
  install_prerequisites
  configure_docker_repository
  install_docker
  start_and_enable_docker

  # When run under Vagrant, SUDO_USER is the unprivileged user that invoked
  # sudo; that is the account that should be able to use docker directly.
  add_user_to_docker_group "${SUDO_USER:-vagrant}"

  verify_installation

  log "Docker installation complete"
}

main "$@"
