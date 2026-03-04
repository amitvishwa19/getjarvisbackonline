#!/usr/bin/env bash
# Wrapper to run commands with workspace .env loaded
ENV_FILE="/home/ubuntu/.openclaw/workspace/.env"
if [[ -f "$ENV_FILE" ]]; then
  set +u
  source "$ENV_FILE"
  set -u
fi
exec "$@"
