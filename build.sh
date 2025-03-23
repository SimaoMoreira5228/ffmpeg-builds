#!/bin/bash
set -eo pipefail

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
Linux*) ARTIFACT_OS="Linux" ;;
Darwin*) ARTIFACT_OS="macOS" ;;
CYGWIN* | MINGW* | MSYS*) ARTIFACT_OS="Windows" ;;
*)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# Detect ARCH
ARCH=$(uname -m)
case "$ARCH" in
x86_64 | amd64) ARCH="x86_64" ;;
aarch64 | arm64) ARCH="arm64" ;;
*)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Set environment variable for pkg-config
export PKG_CONFIG_PATH="$DEPS_DIR/lib/pkgconfig:$DEPS_DIR/lib/aarch64-linux-gnu/pkgconfig:$DEPS_DIR/lib/x86_64-linux-gnu/pkgconfig:$DEPS_DIR/lib64/pkgconfig"
export PKG_CONFIG="pkg-config --static"

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
        if [ "$ARTIFACT_OS" = "macOS" ]; then
            run_cmd "LIBTOOLIZE=glibtoolize sh autogen.sh"
        else
            run_cmd "sh autogen.sh"
        fi
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
    run_cmd "git clone $repo $dir_name"
    cd "$SRC_DIR/$dir_name"
    run_cmd "$meson_cmd"
    run_cmd "ninja -Cbuild"
    run_cmd "ninja -Cbuild install"
    cd "$SRC_DIR"
}

echo "Building for $ARTIFACT_OS ($ARCH)"

# Build dependencies in order

### 1. zlib
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "git clone https://github.com/madler/zlib.git zlib"
    cd "$SRC_DIR/zlib"
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
    run_cmd "cmake --build build --config Release --target install"
    cd "$SRC_DIR"
else
    build_autotools_dep "https://github.com/madler/zlib.git" "zlib" "sh ./configure --prefix=$DEPS_DIR --static"
fi

### 2. libbrotli
echo "Building libbrotli"
run_cmd "git clone https://github.com/google/brotli.git libbrotli"
libbrotli_build_dir="$SRC_DIR/libbrotli_build"
mkdir -p "$libbrotli_build_dir"
cd "$libbrotli_build_dir"
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "cmake ../libbrotli -G \"Visual Studio 17 2022\" -B build -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
    run_cmd "cmake --build build --config Release --target install"
else
    run_cmd "cmake ../libbrotli -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
    run_cmd "cmake --build . -j$CPU_COUNT"
    run_cmd "cmake --install ."
fi
cd "$SRC_DIR"

### 3. OpenSSL
if [ "$ARTIFACT_OS" = "Windows" ]; then
    config="VC-WIN64A"
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
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "git clone https://github.com/glennrp/libpng.git libpng"
    cd "$SRC_DIR/libpng"
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
    run_cmd "cmake --build build --config Release --target install"
    cd "$SRC_DIR"
else
    build_autotools_dep "https://github.com/glennrp/libpng.git" "libpng" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared" "" "skip"
fi

### 5. harfbuzz
if [ "$ARTIFACT_OS" = "Windows" ]; then
    backend="--backend vs"
else
    backend=""
fi
build_meson_dep "https://github.com/harfbuzz/harfbuzz.git" "harfbuzz" "meson setup build --prefix=$DEPS_DIR --default-library=static $backend"

### 6. freetype2
if [ "$ARTIFACT_OS" = "Windows" ]; then
    backend="--backend vs"
else
    backend=""
fi
build_meson_dep "https://gitlab.freedesktop.org/freetype/freetype.git" "freetype" "meson setup build --prefix=$DEPS_DIR --default-library=static $backend"

### 7. fribidi
if [ "$ARTIFACT_OS" = "Windows" ]; then
    backend="--backend vs"
else
    backend=""
fi
build_meson_dep "https://github.com/fribidi/fribidi.git" "fribidi" "meson setup build --prefix=$DEPS_DIR --default-library=static -Ddocs=false $backend"

### 8. libexpat
echo "Building libexpat"
run_cmd "git clone https://github.com/libexpat/libexpat.git libexpat"
cd "$SRC_DIR/libexpat/expat"
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -EXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_SHARED_LIBS=OFF"
    run_cmd "cmake --build build --config Release --target install"
else
    run_cmd "./buildconf.sh"
    run_cmd "./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
    run_cmd "make -j$CPU_COUNT"
    run_cmd "make install"
fi

### 9. fontconfig
build_autotools_dep "https://gitlab.freedesktop.org/fontconfig/fontconfig.git" "fontconfig" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared --disable-docs --disable-tests --disable-tools --disable-nls"

### 10. libass
if [ "$ARTIFACT_OS" = "Windows" ]; then
    backend="--backend vs"
else
    backend=""
fi
build_meson_dep "https://github.com/libass/libass.git" "libass" "meson setup build --prefix=$DEPS_DIR --default-library=static $backend"

### 11. libfdk-aac
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "git clone https://github.com/mstorsjo/fdk-aac.git fdk-aac"
    cd "$SRC_DIR/fdk-aac"
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
    run_cmd "cmake --build build --config Release --target install"
    cd "$SRC_DIR"
else
    build_autotools_dep "https://github.com/mstorsjo/fdk-aac.git" "fdk-aac" "sh autogen.sh && ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
fi

### 12. libmp3lame
build_autotools_dep "https://github.com/lameproject/lame.git" "lame" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared --enable-nasm --disable-gtktest --disable-frontend"

### 13. libopus
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "git clone https://github.com/xiph/opus.git opus"
    cd "$SRC_DIR/opus"
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DOPUS_BUILD_SHARED_LIBRARY=OFF -DOPUS_BUILD_TESTING=OFF"
    run_cmd "cmake --build build --config Release --target install"
    cd "$SRC_DIR"
else
    build_autotools_dep "https://github.com/xiph/opus.git" "opus" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
fi

### 14. libogg
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "git clone https://github.com/xiph/ogg.git ogg"
    cd "$SRC_DIR/ogg"
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DINSTALL_DOCS=OFF -DBUILD_SHARED_LIBS=OFF"
    run_cmd "cmake --build build --config Release --target install"
    cd "$SRC_DIR"
else
    build_autotools_dep "https://github.com/xiph/ogg.git" "ogg" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
fi

### 15. libvorbis
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "git clone https://gitlab.xiph.org/xiph/vorbis.git vorbis"
    cd "$SRC_DIR/vorbis"
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DBUILD_SHARED_LIBS=OFF"
    run_cmd "cmake --build build --config Release --target install"
    cd "$SRC_DIR"
else
    # we remove `-force_cpusubtype_ALL` from configure.ac for macOS because it's no longer supported on macOS 15 (https://gitlab.xiph.org/xiph/vorbis/-/issues/2352)
    if [ "$ARTIFACT_OS" = "macOS" ]; then
        patch_configure="sed -i '' 's/ -force_cpusubtype_ALL//g' configure.ac"
    else
        patch_configure=""
    fi
    build_autotools_dep "https://gitlab.xiph.org/xiph/vorbis.git" "vorbis" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared --with-ogg=$DEPS_DIR" "$patch_configure"
fi

### 16. libvpx
build_autotools_dep "https://github.com/webmproject/libvpx.git" "libvpx" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"

### 17. libx264
build_autotools_dep "https://code.videolan.org/videolan/x264.git" "x264" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-opencl --disable-bashcompletion --extra-cflags=\"-fPIC\""

### 18. libx265
echo "Building x265"
run_cmd "git clone https://bitbucket.org/multicoreware/x265_git.git x265"
if [ "$ARTIFACT_OS" = "Windows" ]; then
    build_dir="build/linux"
    cmake_cmd="cmake -G \"Visual Studio 17 2022\" ../../source && cmake ../../source -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
elif [ "$ARTIFACT_OS" = "Linux" ] && [ "$ARCH" = "arm64" ]; then
    build_dir="build/aarch64-linux"
    cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DENABLE_SVE2=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
elif [ "$ARTIFACT_OS" = "macOS" ] && [ "$ARCH" = "arm64" ]; then
    build_dir="build/aarch64-darwin"
    cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
elif [ "$ARTIFACT_OS" = "macOS" ]; then
    build_dir="build/linux"
    cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DENABLE_ASSEMBLY=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
else
    build_dir="build/linux"
    cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
fi
# this goes to release 4.1
cd "$SRC_DIR/x265"
run_cmd "git checkout 1d117bed4747758b51bd2c124d738527e30392cb"
mkdir -p "$build_dir"
cd "$build_dir"
run_cmd "$cmake_cmd"
run_cmd "make -j$CPU_COUNT"
run_cmd "make install"
cd "$SRC_DIR"

### 19. libaom
echo "Building libaom"
run_cmd "git clone https://aomedia.googlesource.com/aom aom"
aom_build_dir="$SRC_DIR/aom_build"
mkdir -p "$aom_build_dir"
cd "$aom_build_dir"
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "cmake ../aom -G \"Visual Studio 17 2022\" -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=0 -DENABLE_DOCS=0 -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
else
    run_cmd "cmake ../aom -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=0 -DENABLE_DOCS=0 -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
fi
run_cmd "cmake --build . -j$CPU_COUNT"
run_cmd "cmake --install ."
cd "$SRC_DIR"

### 20. libwebp
if [ "$ARTIFACT_OS" = "Windows" ]; then
    run_cmd "git clone https://github.com/webmproject/libwebp.git libwebp"
    cd "$SRC_DIR/libwebp"
    run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DBUILD_SHARED_LIBS=OFF"
    run_cmd "cmake --build build --config Release --target install"
    cd "$SRC_DIR"
else
    build_autotools_dep "https://github.com/webmproject/libwebp.git" "libwebp" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
fi

### 21. libdav1d
if [ "$ARTIFACT_OS" = "Windows" ]; then
    backend="--backend vs"
else
    backend=""
fi
build_meson_dep "https://code.videolan.org/videolan/dav1d.git" "dav1d" "meson setup build --prefix=$DEPS_DIR --default-library=static $backend"

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
    configure_cmd="./configure --toolchain=msvc --prefix=$build_dir_version --disable-static --enable-shared --pkg-config-flags=\"--static\" --extra-cflags=\"-I$DEPS_DIR/include\" --extra-ldflags=\"-L$DEPS_DIR/lib\" --enable-gpl --enable-asm --enable-yasm --enable-nonfree --enable-version3 --enable-openssl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libdav1d --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libaom --enable-libwebp --enable-zlib --disable-autodetect"
    run_cmd "$configure_cmd"
    run_cmd "make -j$CPU_COUNT"
    run_cmd "make install"
    artifact_name="ffmpeg-$version-$ARTIFACT_OS-$ARCH.tar.gz"
    echo "Creating artifact: $artifact_name"
    run_cmd "tar -czf $SRC_DIR/$artifact_name -C $build_dir_version ."
    cd "$SRC_DIR"
}

if [ "$ARTIFACT_OS" = "Linux" ]; then
    sudo mv /usr/lib/x86_64-linux-gnu/libfontconfig.so /usr/lib/x86_64-linux-gnu/libfontconfig.so.bak || true
fi

if [ "$ARTIFACT_OS" = "Windows" ]; then
    if [ -f /bin/link.exe ]; then
        sudo rm /bin/link.exe
    fi
fi

# Build FFmpeg versions
build_ffmpeg "7.1" "release/7.1"
build_ffmpeg "6.1" "release/6.1"
build_ffmpeg "master" "master"

if [ "$ARTIFACT_OS" = "Linux" ]; then
    sudo mv /usr/lib/x86_64-linux-gnu/libfontconfig.so.bak /usr/lib/x86_64-linux-gnu/libfontconfig.so || true
fi

echo "Build completed successfully"
