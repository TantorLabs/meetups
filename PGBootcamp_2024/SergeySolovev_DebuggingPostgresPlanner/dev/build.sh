#!/usr/bin/bash

function print_help {
    cat <<EOM
Build PostgreSQL sources
Usage: $0 [-j N|--jobs=N]

Options:

    -j N, --jobs=N      Specify number of threads to use
    -h, --help          Print this help message

Example: $0 -j 12
EOM
}

set -e

THREADS=""
while [ "$1" ]; do
    ARG="$1"
    case $ARG in
    -j)
        shift
        THREADS="$1"
        ;;
    --jobs=*)
        THREADS="${$1#*=}"
        ;;
    -h|--help)
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

if [[ -n "$THREADS" ]]; then
    THREADS="-j $THREADS"
fi

{
    make $THREADS
    make install
    source "$CONFIG_FILE"
    make install-world-bin
} 2>&1 | tee -a $(get_log_file "build")
