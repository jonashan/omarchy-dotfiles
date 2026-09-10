#!/usr/bin/env bash
# Start / stop a Rails dev server (bin/dev) for the browser pass of a review.
#
#   dev-server.sh start   # boot bin/dev on the first free port, wait for it to answer
#   dev-server.sh stop    # stop the server this script started
#
# The review always gets its own server on its own port and its own Rails pidfile, so a
# dev server the user already has running is never touched, reused, or stopped. (Both are
# needed: `rails server` refuses to boot when tmp/pids/server.pid exists, whatever the port.)
set -euo pipefail

cmd="${1:-start}"
base="${PORT:-3000}"
span=20
repo="$(git rev-parse --show-toplevel)"
state="${TMPDIR:-/tmp}/review-dev-$(printf '%s' "$repo" | md5sum | cut -c1-8)"
pidfile="$state.pid"
logfile="$state.log"

port_free() { ! timeout 1 bash -c "exec 3<>/dev/tcp/127.0.0.1/$1" 2>/dev/null; }
answers()   { curl -sf -o /dev/null -m 2 "http://localhost:$1/"; }

# Kill a whole process group — foreman plus every child it spawned.
kill_group() {
  local pgid; pgid="$(ps -o pgid= -p "$1" 2>/dev/null | tr -d ' ' || true)"
  if [[ -n "$pgid" ]]; then kill -"$2" -"$pgid" 2>/dev/null || true
  else kill -"$2" "$1" 2>/dev/null || true; fi
}

case "$cmd" in
  start)
    [[ -x "$repo/bin/dev" ]] || { echo "NO bin/dev in $repo — cannot boot; run the static pass only"; exit 1; }
    [[ -f "$pidfile" ]] && "$0" stop >/dev/null 2>&1

    port=""
    for p in $(seq "$base" $((base + span))); do
      port_free "$p" && { port="$p"; break; }
    done
    [[ -n "$port" ]] || { echo "NO FREE PORT in $base-$((base + span))"; exit 1; }

    ( cd "$repo" && setsid env PORT="$port" PIDFILE="tmp/pids/review-$port.pid" \
        ./bin/dev >"$logfile" 2>&1 </dev/null & echo "$! $port" >"$pidfile" )
    pid="$(cut -d' ' -f1 "$pidfile")"

    for _ in $(seq 1 90); do
      answers "$port" && { echo "STARTED  pid $pid  http://localhost:$port/  log $logfile"; exit 0; }
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done

    echo "FAILED to answer on http://localhost:$port/ — last 30 log lines:"
    tail -n 30 "$logfile" 2>/dev/null || true
    "$0" stop >/dev/null 2>&1 || true
    exit 1
    ;;

  stop)
    [[ -f "$pidfile" ]] || { echo "NOTHING TO STOP (this script did not start a server)"; exit 0; }
    read -r pid port <"$pidfile"

    # Resolve the process actually listening on our port: `setsid` forks, so the pid we
    # recorded is not foreman, and killing it leaves the whole tree orphaned.
    listener="$(ss -ltnpH "sport = :$port" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1 || true)"
    kill_group "${listener:-$pid}" TERM

    for _ in $(seq 1 10); do port_free "$port" && break; sleep 1; done
    if ! port_free "$port"; then
      listener="$(ss -ltnpH "sport = :$port" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1 || true)"
      [[ -n "$listener" ]] && kill_group "$listener" KILL
    fi

    rm -f "$pidfile" "$repo/tmp/pids/review-$port.pid"
    port_free "$port" && echo "STOPPED  (port $port)" || echo "WARNING: port $port still in use after stop"
    ;;

  *) echo "usage: dev-server.sh start|stop" >&2; exit 2 ;;
esac
