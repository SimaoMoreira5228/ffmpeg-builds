#!/bin/env bash
set -eo pipefail

export PKG_CONFIG="pkg-config --static"

OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    Darwin | Linux)
        cmake_generator="Ninja"
        ;;
    CYGWIN* | MINGW* | MSYS*)
        cmake_generator="Visual Studio 17 2022"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

if [ "$OS" = "Darwin" ]; then
    CPU_COUNT=$(sysctl -n hw.ncpu)
else
    CPU_COUNT=$(nproc)
fi

function build_ffmpeg() {
    local tag=$1
    local install_dir="install/$tag"
    local tar_name="ffmpeg-$tag-$OS-$ARCH"
    echo "::group::Building ffmpeg $tag"

    cmake -G${cmake_generator} -B build -DCMAKE_INSTALL_PREFIX=$install_dir -DCMAKE_BUILD_TYPE=Release -DFFMPEG_TAG=$tag
    cmake --build build --config Release --parallel ${CPU_COUNT} --target install

    mkdir -p tmp/$tar_name
    cp -a $install_dir/. tmp/$tar_name/

    tar -czf $tar_name.tar.gz -C tmp $tar_name
    rm -rf tmp/$tar_name

    echo "::notice ::Done building ffmpeg $tag - $(du -sh $tar_name.tar.gz)"
    echo "::endgroup::"
}

build_ffmpeg "n6.1"
build_ffmpeg "n7.1"
build_ffmpeg "master"
