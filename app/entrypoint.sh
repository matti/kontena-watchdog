#!/usr/bin/env sh
set -e
case "$1" in
  "web")
    if [ "$RACK_ENV" = "development" ]; then
      exec rerun "rackup -s Puma -o 0.0.0.0 -p ${PORT:-8080}"
    else
      exec rackup -s Puma -o 0.0.0.0 -p ${PORT:-8080}
    fi
  ;;
  *)
    echo "Unknown process: $1"
    exit 1
  ;;
esac
