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
export PKG_CONFIG_PATH="$DEPS_DIR/lib/pkgconfig:$DEPS_DIR/lib/aarch64-linux-gnu/pkgconfig:$DEPS_DIR/lib/x86_64-linux-gnu/pkgconfig:$DEPS_DIR/lib64/pkgconfig"

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

# Build dependencies in order

### 1. zlib
build_autotools_dep "https://github.com/madler/zlib.git" "zlib" "sh ./configure --prefix=$DEPS_DIR --static CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""

### 2. libbrotli
echo "Building libbrotli"
run_cmd "git clone https://github.com/google/brotli.git libbrotli"
libbrotli_build_dir="$SRC_DIR/libbrotli_build"
mkdir -p "$libbrotli_build_dir"
cd "$libbrotli_build_dir"
run_cmd "cmake ../libbrotli -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""
run_cmd "cmake --build . -j$CPU_COUNT"
run_cmd "cmake --install ."
cd "$SRC_DIR"

### 3. OpenSSL
if [ "$ARTIFACT_OS" = "Windows" ]; then
    config="mingw64"
elif [ "$ARTIFACT_OS" = "macOS" ]; then
    if [ "$ARCH" = "arm64" ]; then
        config="darwin64-arm64-cc"
    else
        config="darwin64-x86_64-cc"
    fi
elif [ "$ARTIFACT_OS" = "Linux" ]; then
    if [ "$ARCH" = "arm64" ]; then
        config="linux-aarch64"
    else
        config="linux-x86_64"
    fi
else
    echo "Unsupported OS: $ARTIFACT_OS"
    exit 1
fi
openssl_configure="perl ./Configure $config --prefix=$DEPS_DIR --openssldir=$DEPS_DIR/ssl no-shared no-docs no-tests"
build_autotools_dep "https://github.com/openssl/openssl.git" "openssl" "$openssl_configure"

### 4. libpng
build_autotools_dep "https://github.com/glennrp/libpng.git" "libpng" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\"" "" "skip"

### 5. harfbuzz
build_meson_dep "https://github.com/harfbuzz/harfbuzz.git" "harfbuzz" "meson setup build --prefix=$DEPS_DIR --default-library=static"

### 6. freetype2
build_meson_dep "https://gitlab.freedesktop.org/freetype/freetype.git" "freetype" "meson setup build --prefix=$DEPS_DIR --default-library=static"

### 7. fribidi
build_meson_dep "https://github.com/fribidi/fribidi.git" "fribidi" "meson setup build --prefix=$DEPS_DIR --default-library=static -Ddocs=false"

### 8. fontconfig
build_meson_dep "https://gitlab.freedesktop.org/fontconfig/fontconfig.git" "fontconfig" "meson setup build --prefix=$DEPS_DIR --default-library=static"

### 9. libass
build_meson_dep "https://github.com/libass/libass.git" "libass" "meson setup build --prefix=$DEPS_DIR --default-library=static"

### 10. libfdk-aac
build_autotools_dep "https://github.com/mstorsjo/fdk-aac.git" "fdk-aac" "sh autogen.sh && ./configure --prefix=$DEPS_DIR --enable-static --disable-shared CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""

### 11. libmp3lame
build_autotools_dep "https://github.com/lameproject/lame.git" "lame" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared --enable-nasm --disable-gtktest --disable-frontend CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""

### 12. libopus
build_autotools_dep "https://github.com/xiph/opus.git" "opus" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""

### 13. libogg
build_autotools_dep "https://github.com/xiph/ogg.git" "ogg" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""

### 14. libvorbis
# we remove `-force_cpusubtype_ALL` from configure.ac for macOS because it's no longer supported on macOS 15 (https://gitlab.xiph.org/xiph/vorbis/-/issues/2352)
if [ "$ARTIFACT_OS" = "macOS" ]; then
    patch_configure="sed -i '' 's/ -force_cpusubtype_ALL//g' configure.ac"
else
    patch_configure=""
fi
build_autotools_dep "https://gitlab.xiph.org/xiph/vorbis.git" "vorbis" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared --with-ogg=$DEPS_DIR CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\"" "$patch_configure"

### 15. libvpx
build_autotools_dep "https://github.com/webmproject/libvpx.git" "libvpx" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"

### 16. libx264
build_autotools_dep "https://code.videolan.org/videolan/x264.git" "x264" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-opencl --disable-bashcompletion --extra-cflags=\"-fPIC\" CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""

### 17. libx265
echo "Building x265"
run_cmd "git clone https://bitbucket.org/multicoreware/x265_git.git x265"
if [ "$ARTIFACT_OS" = "Windows" ]; then
    build_dir="build/linux"
    cmake_cmd="cmake -G \"MSYS Makefiles\" ../../source && cmake ../../source -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""
elif [ "$ARTIFACT_OS" = "Linux" ] && [ "$ARCH" = "arm64" ]; then
    build_dir="build/aarch64-linux"
    cmake_cmd="cmake ../../source -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=OFF -DENABLE_SVE2=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""
elif [ "$ARTIFACT_OS" = "macOS" ] && [ "$ARCH" = "arm64" ]; then
    build_dir="build/aarch64-darwin"
    cmake_cmd="cmake ../../source -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""
elif [ "$ARTIFACT_OS" = "macOS" ]; then
    build_dir="build/linux"
    cmake_cmd="cmake ../../source -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=OFF -DENABLE_ASSEMBLY=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""
else
    build_dir="build/linux"
    cmake_cmd="cmake ../../source -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""
fi
x265_dir="$SRC_DIR/x265/$build_dir"
mkdir -p "$x265_dir"
cd "$x265_dir"
run_cmd "$cmake_cmd"
run_cmd "make -j$CPU_COUNT"
run_cmd "make install"
cd "$SRC_DIR"

### 18. libaom
echo "Building libaom"
run_cmd "git clone https://aomedia.googlesource.com/aom aom"
aom_build_dir="$SRC_DIR/aom_build"
mkdir -p "$aom_build_dir"
cd "$aom_build_dir"
run_cmd "cmake ../aom -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=0 -DENABLE_DOCS=0 CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\" -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
run_cmd "cmake --build . -j$CPU_COUNT"
run_cmd "cmake --install ."
cd "$SRC_DIR"

### 19. libwebp
build_autotools_dep "https://github.com/webmproject/libwebp.git" "libwebp" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared CFLAGS=\"-fPIC\" CXXFLAGS=\"-fPIC\""

### 20. libdav1d
build_meson_dep "https://code.videolan.org/videolan/dav1d.git" "dav1d" "meson setup build --prefix=$DEPS_DIR --default-library=static"

# Function to build FFmpeg
build_ffmpeg() {
    version=$1
    branch=$2
    echo "Building FFmpeg $version"
    ffmpeg_dir="$SRC_DIR/ffmpeg-$version"
    build_dir_version="$BUILD_DIR/ffmpeg-$version"
    mkdir -p "$build_dir_version"
    run_cmd "git clone --depth 1 --branch $branch https://github.com/FFmpeg/FFmpeg.git ffmpeg-$version"
    cd "$ffmpeg_dir"
    configure_cmd="./configure --prefix=$build_dir_version --disable-static --enable-shared --pkg-config-flags=\"--static\" --extra-cflags=\"-I$DEPS_DIR/include\" --extra-ldflags=\"-L$DEPS_DIR/lib\" --enable-gpl --enable-nonfree --enable-version3 --enable-openssl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libdav1d --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libaom --enable-libwebp --enable-zlib --disable-autodetect"
    run_cmd "$configure_cmd"
    run_cmd "make -j$CPU_COUNT"
    run_cmd "make install"
    artifact_name="ffmpeg-$version-$ARTIFACT_OS-$ARCH.tar.gz"
    echo "Creating artifact: $artifact_name"
    run_cmd "tar -czf $SRC_DIR/$artifact_name -C $build_dir_version ."
    cd "$SRC_DIR"
}

# Build FFmpeg versions
build_ffmpeg "7.1" "release/7.1"
build_ffmpeg "6.1" "release/6.1"
build_ffmpeg "master" "master"

echo "Build completed successfully"