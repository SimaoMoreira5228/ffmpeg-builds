#!/bin/bash
set -e

# Define directories
HOME_DIR=~
BUILD_DIR="$HOME_DIR/ffmpeg_build"
DEPS_DIR="$HOME_DIR/deps"
SRC_DIR=$(pwd)

# Clean up existing directories
rm -rf "$BUILD_DIR" "$DEPS_DIR"
mkdir -p "$BUILD_DIR" "$DEPS_DIR"

# Detect ARTIFACT_OS
OS=$(uname -s)
case "$OS" in
    Linux*)     ARTIFACT_OS="Linux" ;;
    Darwin*)    ARTIFACT_OS="macOS" ;;
    CYGWIN*|MINGW*|MSYS*) ARTIFACT_OS="Windows" ;;
    *)          echo "Unsupported OS: $OS"; exit 1 ;;
esac

# Detect ARCH
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)   ARCH="x86_64" ;;
    aarch64|arm64)  ARCH="arm64" ;;
    *)              echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Set environment variable for pkg-config
export PKG_CONFIG_PATH="$DEPS_DIR/lib/aarch64-linux-gnu/pkgconfig:$DEPS_DIR/lib/x86_64-linux-gnu/pkgconfig:$DEPS_DIR/lib/pkgconfig"

# Get CPU count
if [ "$ARTIFACT_OS" = "macOS" ]; then
    CPU_COUNT=$(sysctl -n hw.ncpu)
else
    CPU_COUNT=$(nproc)
fi
[ -z "$CPU_COUNT" ] && CPU_COUNT=4
echo "CPU count: $CPU_COUNT"
echo "Detected ARTIFACT_OS: $ARTIFACT_OS, ARCH: $ARCH"

# Helper function to run commands
run_cmd() {
    echo "Running: $1"
    bash -c "$1"
}

# Function to build Autotools-based dependencies
build_autotools_dep() {
    repo=$1
    dir_name=$2
    configure_cmd=$3
    run_before_conf_cmd=$4
    skip_autogen=$5

    echo "Building $dir_name with Autotools"
    run_cmd "git clone --depth 1 $repo $dir_name"
    cd "$SRC_DIR/$dir_name"
    if [ -n "$run_before_conf_cmd" ]; then
        echo "Running pre-configure command for $dir_name"
        run_cmd "$run_before_conf_cmd"
    fi
    if [ -z "$skip_autogen" ] && [ -f "autogen.sh" ]; then
        run_cmd "sh autogen.sh"
    fi
    run_cmd "$configure_cmd"
    run_cmd "make -j$CPU_COUNT"
    run_cmd "make install"
    cd "$SRC_DIR"
}

# Function to build Meson-based dependencies
build_meson_dep() {
    repo=$1
    dir_name=$2
    meson_cmd=$3

    echo "Building $dir_name with Meson"
    run_cmd "git clone --depth 1 $repo $dir_name"
    cd "$SRC_DIR/$dir_name"
    run_cmd "$meson_cmd"
    run_cmd "ninja -Cbuild"
    run_cmd "ninja -Cbuild install"
    cd "$SRC_DIR"
}

echo "Building for $ARTIFACT_OS ($ARCH)"

### 3. libpng
build_autotools_dep "https://github.com/glennrp/libpng.git" "libpng" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\"" "" "skip"

### 7. fontconfig
build_meson_dep "https://gitlab.freedesktop.org/fontconfig/fontconfig.git" "fontconfig" "meson setup build --prefix=$DEPS_DIR --default-library=static"