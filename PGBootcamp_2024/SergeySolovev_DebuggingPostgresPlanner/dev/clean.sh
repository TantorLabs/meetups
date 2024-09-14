#!/usr/bin/bash

function print_help {
    cat <<EOM
Clean files after work
Usage: $0 --full|--build

    --build         Clean build artifacts: object files etc...
    --full          Reset repository to initial state
    -h, --help      Print this help message

Example: $0 --full
EOM
}

FULL=""
BUILD=""

while [[ "$1" ]]; do
    ARG="$1"
    case $ARG in
        --full)
            FULL="1"
            ;;
        --build)
            BUILD="1"
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown argument: $ARG"
            exit 1
            ;;
    esac
    shift
done

source "$(dirname ${BASH_SOURCE[0]:-$0})/utils.sh"

if [[ "$BUILD" ]]; then
    {
        make clean
    } 2>&1 | tee -a $(get_log_file "clean")
fi

if [[ "$FULL" ]]; then
    {
        make distclean
    } 2>&1 | tee -a $(get_log_file "clean")
fi
