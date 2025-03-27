build:
    cmake -GNinja -B build -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release
    cmake --build build --config Release
clean:
    rm -rf build install
