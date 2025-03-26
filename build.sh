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

git config --global advice.detachedHead false
git config --global init.defaultBranch main

# Helper function to run commands
run_cmd() {
    echo "Running: $1"
    bash -c "$1"
}

git_clone() {
    repo=$1
    commit=$2
    dir_name=$3
    
    mkdir -p $dir_name
    pushd $dir_name
    git init
    git remote add origin $repo
    git fetch --depth=1 origin $commit
    git checkout $commit
    popd
}

# Function to build Autotools-based dependencies
build_autotools_dep() {
    repo=$1
    commit=$2
    dir_name=$3
    configure_cmd=$4
    run_before_conf_cmd=$5
    skip_autogen=$6

    echo "Building $dir_name with Autotools"
    echo "Checking out commit $commit for $dir_name"
    git_clone $repo $commit $dir_name
    pushd $dir_name

    if [ "$ARTIFACT_OS" = "Windows" ]; then
        find . -type f -name "*.sh" -exec dos2unix {} \;
    fi

    if [ -n "$run_before_conf_cmd" ]; then
        echo "Running pre-configure command for $dir_name"
        run_cmd "$run_before_conf_cmd"
    fi
    if [ -z "$skip_autogen" ] && [ -f "autogen.sh" ]; then
        if [ "$ARTIFACT_OS" = "Windows" ]; then
            run_cmd "sh autogen.sh || (echo 'autogen.sh failed'; exit 1)"
        elif [ "$ARTIFACT_OS" = "macOS" ]; then
            run_cmd "LIBTOOLIZE=glibtoolize sh autogen.sh || (echo 'autogen.sh failed'; exit 1)"
        else
            run_cmd "sh autogen.sh || (echo 'autogen.sh failed'; exit 1)"
        fi
    fi

    run_cmd "$configure_cmd || (echo 'configure failed'; exit 1)"
    run_cmd "make -j$CPU_COUNT"
    run_cmd "make install"
    popd
}

# Function to build Meson-based dependencies
build_meson_dep() {
    repo=$1
    commit=$2
    dir_name=$3
    meson_opts=$4

    echo "Building $dir_name with Meson"
    echo "Checking out commit $commit for $dir_name"
    git_clone $repo $commit $dir_name
    pushd $dir_name

    if [ "$ARTIFACT_OS" = "Windows" ]; then
        run_cmd "meson setup build --prefix=$DEPS_DIR --default-library=static --buildtype=release $meson_opts --backend vs"
    else
        run_cmd "meson setup build --prefix=$DEPS_DIR --default-library=static --buildtype=release $meson_opts"
    fi

    meson compile -C build
    meson install -C build
    popd
}

build_cmake_dep() {
    repo=$1
    commit=$2
    dir_name=$3
    cmake_opts=$4
    pre_cmake_cmd=$5

    echo "Building $dir_name with CMake"
    echo "Checking out commit $commit for $dir_name"
    git_clone $repo $commit $dir_name
    pushd $dir_name

    if [ "$ARTIFACT_OS" = "Windows" ]; then
        find . -type f -name "*.awk" -exec dos2unix {} \;
    fi

    if [ -n "$pre_cmake_cmd" ]; then
        echo "Running pre-cmake command for $dir_name"
        eval "$pre_cmake_cmd"
    fi

    if [ "$ARTIFACT_OS" = "Windows" ]; then
        pwd
        run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DCMAKE_BUILD_TYPE=Release $cmake_opts"
        run_cmd "cmake --build build --config Release --target install"
    else
        run_cmd "cmake -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DCMAKE_BUILD_TYPE=Release $cmake_opts"
        run_cmd "cmake --build build -j$CPU_COUNT --config Release --target install"
    fi

    popd
}

echo "Building for $ARTIFACT_OS ($ARCH)"

# Build dependencies in order

### 1. zlib
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "git clone https://github.com/madler/zlib.git zlib"
#     cd "$SRC_DIR/zlib"
#     # check out commit 51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf refering to tag v1.3.1
#     run_cmd "git checkout 51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf"

#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
#     run_cmd "cmake --build build --config Release --target install"
#     cd "$SRC_DIR"
# else
#     # check out commit 51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf refering to tag v1.3.1
#     build_autotools_dep "https://github.com/madler/zlib.git" "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf" "zlib" "sh ./configure --prefix=$DEPS_DIR --static"
# fi
echo "Building zlib"
build_cmake_dep "https://github.com/madler/zlib.git" "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf" "zlib" "-DZLIB_BUILD_SHARED=OFF"

### 2. libbrotli
echo "Building libbrotli"
build_cmake_dep "https://github.com/google/brotli.git" "ed738e842d2fbdf2d6459e39267a633c4a9b2f5d" "libbrotli" "-DBUILD_SHARED_LIBS=OFF"

### 3. OpenSSL
if [ "$ARTIFACT_OS" = "Windows" ]; then
    config="VC-WIN64A"
    perl="/c/Strawberry/perl/bin/perl"
elif [ "$ARTIFACT_OS" = "macOS" ]; then
    if [ "$ARCH" = "arm64" ]; then
        config="darwin64-arm64-cc"
    else
        config="darwin64-x86_64-cc"
    fi
    perl="perl"
elif [ "$ARTIFACT_OS" = "Linux" ]; then
    if [ "$ARCH" = "arm64" ]; then
        config="linux-aarch64"
    else
        config="linux-x86_64"
    fi
    perl="perl"
else
    echo "Unsupported OS: $ARTIFACT_OS"
    exit 1
fi

openssl_configure="$perl ./Configure $config --prefix=$DEPS_DIR --openssldir=$DEPS_DIR/ssl no-shared no-docs no-tests"

# check out commit 0c6656a7a31492ddd61e3d0d8b0e66645f4b2d6f refering to tag openssl-3.5.0-beta1
# build_autotools_dep "https://github.com/openssl/openssl.git" "0c6656a7a31492ddd61e3d0d8b0e66645f4b2d6f" "openssl" "$openssl_configure"

### 4. libpng
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "git clone https://github.com/glennrp/libpng.git libpng"
#     cd "$SRC_DIR/libpng"
#     # check out commit 872555f4ba910252783af1507f9e7fe1653be252 refering to tag v1.6.47
#     run_cmd "git checkout 872555f4ba910252783af1507f9e7fe1653be252"

#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
#     run_cmd "cmake --build build --config Release --target install"
#     cd "$SRC_DIR"
# else
#     # check out commit 872555f4ba910252783af1507f9e7fe1653be252 refering to tag v1.6.47
#     build_autotools_dep "https://github.com/glennrp/libpng.git" "872555f4ba910252783af1507f9e7fe1653be252" "libpng" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared" "" "skip"
# fi

echo "Building libpng"
build_cmake_dep "https://github.com/glennrp/libpng.git" "872555f4ba910252783af1507f9e7fe1653be252" "libpng" "-DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF"

### 5. harfbuzz
# check out commit ea6a172f84f2cbcfed803b5ae71064c7afb6b5c2 refering to tag 11.0.0
build_meson_dep "https://github.com/harfbuzz/harfbuzz.git" "ea6a172f84f2cbcfed803b5ae71064c7afb6b5c2" "harfbuzz"

### 6. freetype2
# check out commit 42608f77f20749dd6ddc9e0536788eaad70ea4b5 refering to tag VER-2-13-3
build_meson_dep "https://github.com/freetype/freetype.git" "42608f77f20749dd6ddc9e0536788eaad70ea4b5" "freetype"

### 7. fribidi
# check out commit 68162babff4f39c4e2dc164a5e825af93bda9983 refering to tag v1.0.16
build_meson_dep "https://github.com/fribidi/fribidi.git" "68162babff4f39c4e2dc164a5e825af93bda9983" "fribidi" "-Ddocs=false"

### 8. libexpat
echo "Building libexpat"
# run_cmd "git clone https://github.com/libexpat/libexpat.git libexpat"
# cd "$SRC_DIR/libexpat/expat"
# # check out commit 6d4ffe856df497ac2cae33537665c3fec7ec8a00 refering to tag R_2_7_0
# run_cmd "git checkout 6d4ffe856df497ac2cae33537665c3fec7ec8a00"
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_SHARED_LIBS=OFF"
#     run_cmd "cmake --build build --config Release --target install"
# else
#     run_cmd "./buildconf.sh"
#     run_cmd "./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
#     run_cmd "make -j$CPU_COUNT"
#     run_cmd "make install"
# fi
build_cmake_dep "https://github.com/libexpat/libexpat.git" "6d4ffe856df497ac2cae33537665c3fec7ec8a00" "libexpat" "-DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_SHARED_LIBS=OFF" "cd expat"

if [ "$ARTIFACT_OS" = "Windows" ]; then
    export FREETYPE_CFLAGS="-I$DEPS_DIR/include/freetype2"
    export FREETYPE_LIBS="-L$DEPS_DIR/lib -lfreetype"
    export EXPAT_CFLAGS="-I$DEPS_DIR/include"
    export EXPAT_LIBS="-L$DEPS_DIR/lib -lexpatMD"
    export FONTCONFIG_CFLAGS="-I$DEPS_DIR/include"
fi

### 9. fontconfig
# check out commit fdfc3445d1cc9c1c7e587fb2a1287871de16faf9 refering to tag 2.16.1
# build_autotools_dep "https://github.com/ScuffleCloud/fontconfig-mirror.git" "fdfc3445d1cc9c1c7e587fb2a1287871de16faf9" "fontconfig" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared --disable-docs --disable-tests --disable-tools --disable-nls --target=msvc"
build_meson_dep "https://github.com/ScuffleCloud/fontconfig-mirror.git" "f511346fe16f205f087a97faf32d3c7d07d5b3c8" "fontconfig" "-Ddocs=false -Dtests=false -Dtools=false"

### 10. libass
# check out commit e46aedea0a0d17da4c4ef49d84b94a7994664ab5 refering to tag 0.17.3
build_meson_dep "https://github.com/libass/libass.git" "e46aedea0a0d17da4c4ef49d84b94a7994664ab5" "libass"

### 11. libfdk-aac
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "git clone https://github.com/ScuffleCloud/fdk-aac-mirror.git fdk-aac"
#     cd "$SRC_DIR/fdk-aac"
#     # check out commit 716f4394641d53f0d79c9ddac3fa93b03a49f278 refering to tag v2.0.3
#     run_cmd "git checkout 716f4394641d53f0d79c9ddac3fa93b03a49f278"
#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
#     run_cmd "cmake --build build --config Release --target install"
#     cd "$SRC_DIR"
# else
#     # check out commit 716f4394641d53f0d79c9ddac3fa93b03a49f278 refering to tag v2.0.3
#     build_autotools_dep "https://github.com/ScuffleCloud/fdk-aac-mirror.git" "716f4394641d53f0d79c9ddac3fa93b03a49f278" "fdk-aac" "sh autogen.sh && ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
# fi
echo "Building fdk-aac"
build_cmake_dep "https://github.com/ScuffleCloud/fdk-aac-mirror.git" "716f4394641d53f0d79c9ddac3fa93b03a49f278" "fdk-aac" "-DBUILD_SHARED_LIBS=OFF"

### 12. libmp3lame
run_cmd "curl -L -o lame-3.100.tar.gz https://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz/download"
run_cmd "tar -xzf lame-3.100.tar.gz"

pushd lame-3.100
run_cmd "./configure --prefix=$DEPS_DIR --enable-static --disable-shared --enable-nasm --disable-gtktest --disable-frontend"
run_cmd "make -j$CPU_COUNT"
run_cmd "make install"
popd

### 13. libopus
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "git clone https://github.com/xiph/opus.git opus"
#     cd "$SRC_DIR/opus"
#     # check out commit ddbe48383984d56acd9e1ab6a090c54ca6b735a6 refering to tag v1.5.2
#     run_cmd "git checkout ddbe48383984d56acd9e1ab6a090c54ca6b735a6"

#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DOPUS_BUILD_SHARED_LIBRARY=OFF -DOPUS_BUILD_TESTING=OFF"
#     run_cmd "cmake --build build --config Release --target install"
#     cd "$SRC_DIR"
# else
#     # check out commit ddbe48383984d56acd9e1ab6a090c54ca6b735a6 refering to tag v1.5.2
#     build_autotools_dep "https://github.com/xiph/opus.git" "ddbe48383984d56acd9e1ab6a090c54ca6b735a6" "opus" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
# fi
echo "Building opus"
build_cmake_dep "https://github.com/xiph/opus.git" "ddbe48383984d56acd9e1ab6a090c54ca6b735a6" "opus" "-DOPUS_BUILD_SHARED_LIBRARY=OFF -DOPUS_BUILD_TESTING=OFF"

### 14. libogg
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "git clone https://github.com/xiph/ogg.git ogg"
#     cd "$SRC_DIR/ogg"
#     # check out commit e1774cd77f471443541596e09078e78fdc342e4f refering to tag v1.3.5
#     run_cmd "git checkout e1774cd77f471443541596e09078e78fdc342e4f"
#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DINSTALL_DOCS=OFF -DBUILD_SHARED_LIBS=OFF"
#     run_cmd "cmake --build build --config Release --target install"
#     cd "$SRC_DIR"
# else
#     # check out commit e1774cd77f471443541596e09078e78fdc342e4f refering to tag v1.3.5
#     build_autotools_dep "https://github.com/xiph/ogg.git" "e1774cd77f471443541596e09078e78fdc342e4f" "ogg" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
# fi
echo "Building ogg"
build_cmake_dep "https://github.com/xiph/ogg.git" "e1774cd77f471443541596e09078e78fdc342e4f" "ogg" "-DINSTALL_DOCS=OFF -DBUILD_SHARED_LIBS=OFF"

### 15. libvorbis
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "git clone https://github.com/xiph/vorbis.git vorbis"
#     cd "$SRC_DIR/vorbis"

#     # check out commit 0657aee69dec8508a0011f47f3b69d7538e9d262 refering to tag v1.3.7
#     run_cmd "git checkout 0657aee69dec8508a0011f47f3b69d7538e9d262"

#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DBUILD_SHARED_LIBS=OFF"
#     run_cmd "cmake --build build --config Release --target install"
#     cd "$SRC_DIR"
# else
#     # we remove `-force_cpusubtype_ALL` from configure.ac for macOS because it's no longer supported on macOS 15 (https://gitlab.xiph.org/xiph/vorbis/-/issues/2352)
#     if [ "$ARTIFACT_OS" = "macOS" ]; then
#         patch_configure="sed -i '' 's/ -force_cpusubtype_ALL//g' configure.ac"
#     else
#         patch_configure=""
#     fi

#     # check out commit 0657aee69dec8508a0011f47f3b69d7538e9d262 refering to tag v1.3.7
#     build_autotools_dep "https://github.com/xiph/vorbis.git" "0657aee69dec8508a0011f47f3b69d7538e9d262" "vorbis" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared --with-ogg=$DEPS_DIR" "$patch_configure"
# fi
echo "Building vorbis"
if [ "$ARTIFACT_OS" = "macOS" ]; then
    patch_configure="sed -i '' 's/ -force_cpusubtype_ALL//g' configure.ac"
else
    patch_configure=""
fi
build_cmake_dep "https://github.com/xiph/vorbis.git" "0657aee69dec8508a0011f47f3b69d7538e9d262" "vorbis" "-DBUILD_SHARED_LIBS=OFF $patch_configure"

### 16. libvpx
# check out commit 39e8b9dcd4696d9ac3ebd4722e012488382f1adb refering to tag v1.15.1-rc1
build_autotools_dep "https://github.com/webmproject/libvpx.git" "39e8b9dcd4696d9ac3ebd4722e012488382f1adb" "libvpx" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"

### 17. libx264
# check out commit 0e48d072c28b6e5283d94109391f8efbb52593f2 refering to https://code.videolan.org/videolan/x264/-/commit/0e48d072c28b6e5283d94109391f8efbb52593f2
build_autotools_dep "https://github.com/ScuffleCloud/x264-mirror.git" "0e48d072c28b6e5283d94109391f8efbb52593f2" "x264" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-opencl --disable-bashcompletion --extra-cflags=\"-fPIC\""

### 18. libx265
echo "Building x265"
# run_cmd "git clone https://github.com/ScuffleCloud/x265-mirror.git x265"
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     build_dir="build/linux"
#     cmake_cmd="cmake -G \"Visual Studio 17 2022\" ../../source && cmake ../../source -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
# elif [ "$ARTIFACT_OS" = "Linux" ] && [ "$ARCH" = "arm64" ]; then
#     build_dir="build/aarch64-linux"
#     cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DENABLE_SVE2=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
# elif [ "$ARTIFACT_OS" = "macOS" ] && [ "$ARCH" = "arm64" ]; then
#     build_dir="build/aarch64-darwin"
#     cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
# elif [ "$ARTIFACT_OS" = "macOS" ]; then
#     build_dir="build/linux"
#     cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DENABLE_ASSEMBLY=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
# else
#     build_dir="build/linux"
#     cmake_cmd="cmake ../../source -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
# fi
# cd "$SRC_DIR/x265"
# # check out commit 1d117bed4747758b51bd2c124d738527e30392cb refering to tag v4.1
# run_cmd "git checkout 1d117bed4747758b51bd2c124d738527e30392cb"
# mkdir -p "$build_dir"
# cd "$build_dir"
# run_cmd "$cmake_cmd"
# run_cmd "make -j$CPU_COUNT"
# run_cmd "make install"
# cd "$SRC_DIR"
build_cmake_dep "https://github.com/ScuffleCloud/x265-mirror.git" "1d117bed4747758b51bd2c124d738527e30392cb" "x265" "-DENABLE_SHARED=OFF"

### 19. libaom
echo "Building libaom"
# run_cmd "git clone https://github.com/ScuffleCloud/aom-mirror.git aom"
# cd "$SRC_DIR/aom"

# # check out commit 3b624af45b86646a20b11a9ff803aeae588cdee6 refering to tag v3.12.0
# run_cmd "git checkout 3b624af45b86646a20b11a9ff803aeae588cdee6"

# aom_build_dir="$SRC_DIR/aom_build"
# mkdir -p "$aom_build_dir"
# cd "$aom_build_dir"
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "cmake ../aom -G \"Visual Studio 17 2022\" -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=0 -DENABLE_DOCS=0 -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
# else
#     run_cmd "cmake ../aom -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=0 -DENABLE_DOCS=0 -DCMAKE_INSTALL_PREFIX=$DEPS_DIR"
# fi
# run_cmd "cmake --build . -j$CPU_COUNT"
# run_cmd "cmake --install ."
# cd "$SRC_DIR"
build_cmake_dep "https://github.com/ScuffleCloud/aom-mirror.git" "3b624af45b86646a20b11a9ff803aeae588cdee6" "aom" "-DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=0 -DENABLE_DOCS=0"

### 20. libwebp
# if [ "$ARTIFACT_OS" = "Windows" ]; then
#     run_cmd "git clone https://github.com/webmproject/libwebp.git libwebp"
#     cd "$SRC_DIR/libwebp"
#     # check out commit a4d7a715337ded4451fec90ff8ce79728e04126c refering to tag v1.5.0
#     run_cmd "git checkout a4d7a715337ded4451fec90ff8ce79728e04126c"

#     run_cmd "cmake -G \"Visual Studio 17 2022\" -B build -DCMAKE_INSTALL_PREFIX=$DEPS_DIR -DBUILD_SHARED_LIBS=OFF"
#     run_cmd "cmake --build build --config Release --target install"
#     cd "$SRC_DIR"
# else
#     build_autotools_dep "https://github.com/webmproject/libwebp.git" "a4d7a715337ded4451fec90ff8ce79728e04126c" "libwebp" "sh ./configure --prefix=$DEPS_DIR --enable-static --disable-shared"
# fi
echo "Building libwebp"
build_cmake_dep "https://github.com/webmproject/libwebp.git" "a4d7a715337ded4451fec90ff8ce79728e04126c" "libwebp" "-DBUILD_SHARED_LIBS=OFF"

### 21. libdav1d
# check out commit 42b2b24fb8819f1ed3643aa9cf2a62f03868e3aa refering to tag 1.5.1
build_meson_dep "https://github.com/videolan/dav1d.git" "42b2b24fb8819f1ed3643aa9cf2a62f03868e3aa" "dav1d"

# Function to build FFmpeg
# Build FFmpeg versions (Modified to build static libraries)
build_ffmpeg() {
    version=$1
    branch=$2
    echo "Building FFmpeg $version"
    ffmpeg_dir="$SRC_DIR/ffmpeg-$version"
    build_dir_version="$BUILD_DIR/ffmpeg-$version"
    mkdir -p "$build_dir_version"
    run_cmd "git clone --depth 1 --branch $branch https://github.com/FFmpeg/FFmpeg.git ffmpeg-$version"
    pushd "$ffmpeg_dir"

    if [ "$ARTIFACT_OS" = "Windows" ]; then
        configure_cmd="./configure --toolchain=msvc --prefix=$build_dir_version --enable-static --disable-shared --pkg-config-flags=\"--static\" --extra-cflags=\"-I$DEPS_DIR/include\" --extra-ldflags=\"-L$DEPS_DIR/lib\" --enable-gpl --enable-asm --enable-yasm --enable-nonfree --enable-version3 --enable-openssl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libdav1d --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libaom --enable-libwebp --enable-zlib --disable-autodetect"
    else
        configure_cmd="./configure --prefix=$build_dir_version --enable-static --disable-shared --pkg-config-flags=\"--static\" --extra-cflags=\"-I$DEPS_DIR/include\" --extra-ldflags=\"-L$DEPS_DIR/lib\" --enable-gpl --enable-asm --enable-yasm --enable-nonfree --enable-version3 --enable-openssl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libdav1d --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libaom --enable-libwebp --enable-zlib --disable-autodetect"
    fi

    run_cmd "$configure_cmd"
    run_cmd "make -j$CPU_COUNT"
    run_cmd "make install"
    artifact_name="ffmpeg-$version-$ARTIFACT_OS-$ARCH.tar.gz"
    echo "Creating artifact: $artifact_name"
    run_cmd "tar -czf $SRC_DIR/$artifact_name -C $build_dir_version ."
    popd
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
