export PKG_CONFIG := "pkg-config --static"

build tag="master":
    cmake -GNinja -B build -DCMAKE_INSTALL_PREFIX=./install/{{tag}} -DCMAKE_BUILD_TYPE=Release -DFFMPEG_TAG={{tag}}
    cmake --build build --config Release --target install --parallel $(nproc)

clean:
    rm -rf build install
