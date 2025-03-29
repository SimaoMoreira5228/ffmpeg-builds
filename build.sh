#!/bin/env bash
set -eo pipefail

export PKG_CONFIG="pkg-config --static"

OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    Darwin | Linux)
        perl="perl"
        ;;
    CYGWIN* | MINGW* | MSYS*)
        export PATH="~/scoop/apps/perl/current/perl/bin:$PATH"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

if [ "$OS" = "Darwin" ]; then
    export CMAKE_BUILD_PARALLEL_LEVEL=$(sysctl -n hw.ncpu)
    export MACOSX_DEPLOYMENT_TARGET=$(sw_vers -productVersion | cut -d '.' -f 1,2)
else
    export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
fi

function build_ffmpeg() {
    local tag=$1
    local install_dir="install/$tag"
    local tar_name="ffmpeg-$tag-$OS-$ARCH"
    echo "::group::Building ffmpeg $tag"

    cmake -GNinja -B build -DCMAKE_INSTALL_PREFIX=$install_dir -DCMAKE_BUILD_TYPE=Release -DFFMPEG_TAG=$tag -DPERL_BIN=${perl}
    cmake --build build --config Release --parallel ${CMAKE_BUILD_PARALLEL_LEVEL} --target install

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
