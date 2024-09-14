#!/usr/bin/bash

function print_help {
    cat <<EOF
Helper script to obtain pid of running backend for psql.
This info is stored in backend.pid file inside 'build' directory.

Usage: $0

Options:

    -h, --help      Print this help message

Note: designed for single psql process - UB for multiple processes.
EOF
}

source "$(dirname ${BASH_SOURCE[0]:-$0})/utils.sh"

while [ "$1" ]; do
    ARG="$1"
    case "$ARG" in
    -h|--help)
        print_help
        exit 0
        ;;
    *)
        echo "unknown argument $ARG"
        print_help
        exit 4
        ;;
    esac
done
    

PIDFILE="./dev/backend.pid"
if [ ! -f "$PIDFILE" ]; then
  echo "pid file $PIDFILE not found - make sure psql is running"
  exit 1
fi

PIDFILEDATA="$(head -n 1 $PIDFILE)"
if [ -z "$PIDFILEDATA" ]; then
  echo "pid file $PIDFILE is empty - make sure psql started without errors"
  exit 2
fi

if ! ps -p "$PIDFILEDATA" 2>&1 >/dev/null; then
    echo "no process found with pid $PIDFILEDATA"
    exit 3
fi

echo "$PIDFILEDATA"