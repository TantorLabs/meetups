#!/usr/bin/bash

function print_help {
    cat <<EOF
Repository initialization script. Used for 'Debugging PostgreSQL planner' presentation at PG BootCamp.
It:
    1) Downloads PostgreSQL 16.4 source files
    2) Sets up scripts and configuration files 
    3) Sets up VS Code (install extensions)
    4) Applies required patches for source files
    4) Runs setup script

Usage: $0

Options:

    -h|--help\t\t- Shows this help message

EOF
}

FORCE_MODE=""
HAS_GIT="1"

case "$1" in
-f|--force)
    FORCE_MODE="1"
    ;;
-h|--help)
    print_help
    exit 0;
    ;;
"")
    ;;
*)
    print_help
    exit 1
    ;;
esac

# Set cwd to ./repo
cd "$(dirname "${BASH_SOURCE[0]:-$0}")"

# Stop at first error
set -e

TAR_FILENAME="postgresql-16.4.tar.gz"
UNPACKED_FILENAME="postgresql-16.4"
SRC_DIR="postgresql"
TAR_URI="https://ftp.postgresql.org/pub/source/v16.4/postgresql-16.4.tar.gz"

# Download sources

if [ -f $TAR_FILENAME ] && ! tar tf $TAR_FILENAME >/dev/null 2>&1; then
    rm $TAR_FILENAME
fi


if [ ! -f $TAR_FILENAME ]; then
    echo "Downloading tar file with sources"
    if wget --version >/dev/null 2>&1; then
        wget -O $TAR_FILENAME -q $TAR_URI
    elif curl --verison >/dev/null 2>&1; then
        curl -q --output $TAR_FILENAME $TAR_URI
    else
        echo "Curl or wget not detected"
        echo "Please install curl or wget and try again"
        echo "Or download tar file with sources by your own from"
        echo "$TAR_URI"
        exit 1
    fi
fi

rm -rf $SRC_DIR $UNPACKED_FILENAME

echo "Unpacking source files"
tar xvf $TAR_FILENAME
mv $UNPACKED_FILENAME $SRC_DIR

# Setup dev scripts
echo "Copying development scripts into $SRC_DIR/dev"
cp -r dev $SRC_DIR

# Applying patches
echo "Copying setup files for practice"
cp setup/planmain.c postgresql/src/backend/optimizer/plan/planmain.c
cp setup/Makefile postgresql/src/backend/optimizer/util/Makefile
cp setup/clauses.c postgresql/src/backend/optimizer/util/clauses.c
cp setup/constrexcl.c postgresql/src/backend/optimizer/util/constrexcl.c
cp setup/constrexcl.h postgresql/src/include/optimizer/constrexcl.h

# Configure repository
if [ ! -f "$SRC_DIR/config.status" ]; then
    echo "Running setup script"
    (
        cd $SRC_DIR
        ./dev/setup.sh --configure-args="--without-icu --without-zstd --without-zlib --disable-tap-tests"
    )
else
    echo "Seems that repository already configured - config.status file exists"
    echo "Skipping setup script"
fi


# Setup VS Code
if code --version >/dev/null 2>&1; then
    echo "VS Code detected"
    echo "Copying VS Code configuration files into $SRC_DIR/dev"
    cp -r .vscode $SRC_DIR/
    echo "Installing extension 'C/C++'"
    code --install-extension ms-vscode.cpptools 2>/dev/null || true
    echo "Installing extension 'PostgreSQL Hacker Helper'"
    code --install-extension ash-blade.postgresql-hacker-helper 2>/dev/null || true
fi

echo "--------------------"
echo "Setting up completed"
echo ""
echo "Development scripts located under '$SRC_DIR/dev' folder"
echo "For more info run each of them with '-h' or '--help' flags"
echo "Example: ./dev/build.sh --help"
