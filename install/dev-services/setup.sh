#!/bin/bash
# Runs the local dev services (Postgres + Redis) as Docker containers.
# Ensures the docker daemon is enabled and the user is in the `docker` group.
# Containers restart automatically (unless-stopped), so this only needs
# to create them once; re-runs just start them if they were stopped.
set -euo pipefail

if ! command -v docker &>/dev/null; then
  echo "WARNING: docker not found — skipping dev services"
  exit 0
fi

systemctl is-active --quiet docker || sudo systemctl enable --now docker

if ! id -nG | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "Added $USER to docker group (takes full effect after next login)"
  # Re-run this script with the new group active so it works right now too.
  exec sg docker -c "bash $0"
fi

run_service() {
  local name="$1"; shift
  if [[ -n "$(docker ps -q -f "name=^${name}$")" ]]; then
    echo "Already running: $name"
  elif [[ -n "$(docker ps -aq -f "name=^${name}$")" ]]; then
    docker start "$name" >/dev/null && echo "Started: $name"
  else
    # --name must precede the image; anything after it is the container's own
    # command, which silently produced unnamed crash-looping containers before.
    docker run -d --restart unless-stopped --name "$name" "$@" >/dev/null && echo "Created: $name"
  fi
}

run_service postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres
run_service redis -p 6379:6379 redis

exit 0
