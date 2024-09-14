#!/usr/bin/bash

function print_help {
    cat <<EOM 
Setup environment for PostgreSQL development.
Usage: $0 [--configure-args=ARGS]

Options:
    -h, --help              Print this help message
    --configure-args=ARGS   Additional arguments for configure script

Example:
    $0 --configure-args="--without-icu"
EOM
}

CONFIGURE_ARGS=""
while [ "$1" ]; do
    ARG="$1"
    case "$ARG" in
    --configure-args=*)
        CONFIGURE_ARGS="${ARG#*=}"
        ;;
    --help|-h)
        print_help
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
done

set -e
cd "$(dirname ${BASH_SOURCE[0]:-$0})/.."

CFLAGS="-O0 -g $CFLAGS"
CPPFLAGS="-O0 -g $CPPFLAGS"
INSTALL_PATH="$PWD/build"

{
    ./configure --prefix="$INSTALL_PATH" \
                --enable-debug \
                --enable-cassert \
                --enable-tap-tests \
                --enable-depend \
                CFLAGS="$CFLAGS" \
                CPPFLAGS="$CPPFLAGS" \
                $CONFIGURE_ARGS
    
    PSQLRC_FILE="${PWD}/dev/.psqlrc"
    cat <<EOF >"./dev/pg_dev_config.sh"
export PGINSTDIR="$INSTALL_PATH"
export PGDATA="$INSTALL_PATH/data"
export PGHOST="localhost"
export PGPORT="5432"
export PGUSER="postgres"
export PGDATABASE="postgres"
export PATH="$INSTALL_PATH/bin:\$PATH"
LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:-''}"
export LD_LIBRARY_PATH="\$PGINSTDIR/lib:\$LD_LIBRARY_PATH"
export PSQLRC="${PSQLRC_FILE}"
EOF

    chmod +x "./dev/pg_dev_config.sh"

    cat <<EOF >"$PSQLRC_FILE"
select pg_backend_pid();
EOF
} 2>&1 | tee -a $(get_log_file "setup")

