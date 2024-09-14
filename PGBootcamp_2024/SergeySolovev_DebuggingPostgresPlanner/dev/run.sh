#!/usr/bin/bash

function print_help {
    cat <<EOM
Run database and/or PSQL with settings for current installation.
Log file is written to ./dev/postgresql.log

Usage: $0 [--init-db] [--run-db] [--psql] [--stop-db] [--script=SCRIPT]

    --init-db           Initialize database files
    --run-db            Run database
    --psql              Run PSQL
    --script=SCRIPT     Script for PSQL to run
    --stop-db           Stop running database

Example: $0 --run-db --psql --stop-db
EOM
}

set -e

RUN_DB=""
RUN_PSQL=""
STOP_DB=""
INIT_DB=""
PSQL_SCRIPT=""

while [[ -n "$1" ]]; do
    ARG="$1"
    case "$ARG" in
        --init-db)
            INIT_DB="1"
            ;;
        --run-db)
            RUN_DB="1"
            ;;
        --psql)
            RUN_PSQL="1"
            ;;
        --stop-db)
            STOP_DB="1"
            ;;
        --script=*)
            PSQL_SCRIPT="${ARG#*=}"
            ;;
        --help|-h) 
            print_help
            exit 0
            ;;
        *)
            echo "Unknown argument: $ARG"
            print_help
            exit 1
            ;;
    esac
    shift
done

source "$(dirname ${BASH_SOURCE[0]:-$0})/utils.sh"
source_config_file

if [ "$INIT_DB" ]; then
    {
        initdb -U $PGUSER || true
    } 2>&1 | tee -a $(get_log_file "initdb")
fi

if [ "$RUN_DB" ]; then
    # Not 0 exit code can mean DB already running - do not exit script with error
    {
        pg_ctl start -o '-k ""' -l ./dev/postgresql.log || true
    }  2>&1 | tee -a $(get_log_file "pg_ctl")
fi

if [ "$RUN_PSQL" ]; then
    if [ "$PSQL_SCRIPT" ]; then
        psql -f "$PSQL_SCRIPT"
    else
        psql
        rm -f ./dev/backend.pid
    fi
fi

if [ "$STOP_DB" ]; then
    {
        pg_ctl stop || true
    } 2>&1 | tee -a $(get_log_file "pg_ctl")
fi