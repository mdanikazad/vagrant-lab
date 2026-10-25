#!/usr/bin/env bash
#
# Install Docker Engine on Ubuntu.
#
# Usage:
#   sudo ./scripts/install-docker.sh
#
set -euo pipefail

readonly REQUIRED_COMMANDS=(apt-get curl install)
readonly DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
readonly DOCKER_SOURCE_LIST="/etc/apt/sources.list.d/docker.list"

log() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "This script must be run as root. Try: sudo $0"
  fi
}

require_commands() {
  local command_name
  for command_name in "${REQUIRED_COMMANDS[@]}"; do
    command -v "${command_name}" >/dev/null 2>&1 \
      || die "Required command not found: ${command_name}"
  done
}

update_apt_packages() {
  log "Updating apt package lists"
  apt-get update

  log "Upgrading installed apt packages"
  apt-get upgrade -y
}

install_prerequisites() {
  log "Installing Docker repository prerequisites"
  apt-get install -y ca-certificates curl
}

configure_docker_repository() {
  local architecture codename

  architecture="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}")"

  log "Adding the Docker apt repository for ${codename}/${architecture}"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" -o "${DOCKER_KEYRING}"
  chmod a+r "${DOCKER_KEYRING}"

  printf 'deb [arch=%s signed-by=%s] https://download.docker.com/linux/ubuntu %s stable\n' \
    "${architecture}" "${DOCKER_KEYRING}" "${codename}" > "${DOCKER_SOURCE_LIST}"

  apt-get update
}

install_docker() {
  log "Installing Docker Engine, Buildx, and the Compose plugin"
  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
}

start_and_enable_docker() {
  log "Starting Docker"
  systemctl start docker

  log "Enabling Docker at boot"
  systemctl enable docker
}

verify_installation() {
  log "Verifying the installation"
  systemctl is-active --quiet docker || die "Docker is not active"
  systemctl is-enabled --quiet docker || die "Docker is not enabled"
  docker --version
  docker compose version
}

main() {
  require_root
  require_commands
  update_apt_packages
  install_prerequisites
  configure_docker_repository
  install_docker
  start_and_enable_docker
  verify_installation

  log "Docker installation complete"
}

main "$@"
