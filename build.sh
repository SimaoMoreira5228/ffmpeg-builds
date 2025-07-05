#!/bin/env bash
set -eo pipefail


OS="$(uname -s)"
ARCH="$(uname -m)"

build_dir="${1:build}"

case $OS in
    Darwin | Linux)
        export PKG_CONFIG="pkg-config --static"
        jom_bin=""
        nmake_bin=""
        ;;
    CYGWIN* | MINGW* | MSYS*)
        jom_bin="$(which jom)"
        nmake_bin="$(which nmake)"
        export PKG_CONFIG="$(which pkg-config.exe)"
        ;;
    *)
        echo "Unsupported OS: ${OS}"
        exit 1
        ;;
esac

if [ "$OS" = "Darwin" ]; then
    export CMAKE_BUILD_PARALLEL_LEVEL="$(sysctl -n hw.ncpu)"
    export MACOSX_DEPLOYMENT_TARGET="$(sw_vers -productVersion | cut -d '.' -f 1,2)"
else
    export CMAKE_BUILD_PARALLEL_LEVEL="$(nproc)"
fi

function build_ffmpeg() {
    local tag="$1"
    local install_dir="install/${tag}"
    local tar_name="ffmpeg-${tag}-${OS}-${ARCH}"
    echo "::group::Building ffmpeg ${tag}"

    cmake -GNinja -B "${build_dir}" \
        -DCMAKE_INSTALL_PREFIX="${install_dir}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DFFMPEG_TAG="${tag}" \
        -DBASH_BIN="$(which bash)" \
        -DMAKE_BIN="$(which make)" \
        -DMESON_BIN="$(which meson)" \
        -DPERL_BIN="$(which perl)" \
        -DJOM_BIN="${jom_bin}" \
        -DNMAKE_BIN="${nmake_bin}" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    cmake --build "${build_dir}" --config Release --parallel "${CMAKE_BUILD_PARALLEL_LEVEL}"

    mkdir -p "tmp/${tar_name}"
    cp -a "${install_dir}/." "tmp/${tar_name}/"

    tar -czf "${tar_name}.tar.gz" -C tmp "${tar_name}"
    rm -rf "tmp/${tar_name}"

    echo "::notice ::Done building ffmpeg ${tag} - $(du -sh "${tar_name}.tar.gz")"
    echo "::endgroup::"
}

build_ffmpeg "n6.1"
build_ffmpeg "n7.1"
build_ffmpeg "master"
