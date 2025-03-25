@echo off
setlocal EnableDelayedExpansion

set "check_error=if !ERRORLEVEL! neq 0 (echo Command failed with error !ERRORLEVEL! & exit /b !ERRORLEVEL!)"

:: echo path
echo %PATH%

:: Define directories
set "HOME_DIR=%USERPROFILE%"
set "BUILD_DIR=%HOME_DIR%\ffmpeg_build"
set "DEPS_DIR=%HOME_DIR%\deps"
set "SRC_DIR=%CD%"
set "MSYS2_PATH=C:\msys64\usr\bin"

:: Clean up existing directories
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%DEPS_DIR%" rmdir /s /q "%DEPS_DIR%"
mkdir "%BUILD_DIR%"
mkdir "%DEPS_DIR%"

:: Detect architecture
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if "%ARCH%"=="AMD64" set "ARCH=x86_64"
if "%ARCH%"=="ARM64" set "ARCH=arm64"
if not defined ARCH (
    echo Unsupported architecture: %PROCESSOR_ARCHITECTURE%
    exit /b 1
)

:: Set CPU count
set "CPU_COUNT=%NUMBER_OF_PROCESSORS%"
if not defined CPU_COUNT set "CPU_COUNT=4"
echo CPU count: %CPU_COUNT%
echo Detected OS: Windows, ARCH: %ARCH%

:: Set up Visual Studio environment
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

:: Install Perl module if needed
:: echo Installing Perl module Locale::Maketext::Simple
:: cpan install Locale::Maketext::Simple

:: Build dependencies

:::: 1. zlib
echo Building zlib
git clone https://github.com/madler/zlib.git zlib
cd zlib
cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% & %check_error%
cmake --build build --config Release --target install & %check_error%
cd "%SRC_DIR%"

:::: 2. libbrotli
echo Building libbrotli
git clone https://github.com/google/brotli.git libbrotli
mkdir libbrotli_build
cd libbrotli_build
cmake ../libbrotli -G "Visual Studio 17 2022" -B build -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% & %check_error%
cmake --build build --config Release --target install & %check_error%
cd "%SRC_DIR%"

:::: 3. OpenSSL
@REM echo Building OpenSSL
@REM git clone https://github.com/openssl/openssl.git openssl
@REM cd openssl
@REM "C:\Strawberry\perl\bin\perl.exe" --version & %check_error%
@REM "C:\Strawberry\perl\bin\perl.exe" Configure VC-WIN64A --prefix=%DEPS_DIR% --openssldir=%DEPS_DIR%\ssl no-shared no-docs no-tests & %check_error%
@REM nmake & %check_error%
@REM nmake install & %check_error%
@REM cd "%SRC_DIR%"

:::: 4. libpng
echo Building libpng
git clone https://github.com/glennrp/libpng.git libpng
cd libpng
cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% & %check_error%
cmake --build build --config Release --target install & %check_error%
cd "%SRC_DIR%"

:::: 5. harfbuzz
echo Building harfbuzz
git clone https://github.com/harfbuzz/harfbuzz.git harfbuzz
cd harfbuzz
meson setup build --prefix=%DEPS_DIR% --default-library=static --backend vs & %check_error%
meson compile -C build & %check_error%
meson install -C build & %check_error%
cd "%SRC_DIR%"

:::: 6. freetype2
echo Building freetype
git clone https://gitlab.freedesktop.org/freetype/freetype.git freetype
cd freetype
meson setup build --prefix=%DEPS_DIR% --default-library=static --backend vs & %check_error%
meson compile -C build & %check_error%
meson install -C build & %check_error%
cd "%SRC_DIR%"

:::: 7. fribidi
echo Building fribidi
git clone https://github.com/fribidi/fribidi.git fribidi
cd fribidi
meson setup build --prefix=%DEPS_DIR% --default-library=static -Ddocs=false --backend vs & %check_error%
meson compile -C build & %check_error%
meson install -C build & %check_error%
cd "%SRC_DIR%"

:::: 8. libexpat
echo Building libexpat
git clone https://github.com/libexpat/libexpat.git libexpat
cd libexpat\expat
cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_SHARED_LIBS=OFF & %check_error%
cmake --build build --config Release --target install & %check_error%
cd "%SRC_DIR%"

:::: 9. fontconfig
echo Building fontconfig
git clone https://gitlab.freedesktop.org/fontconfig/fontconfig.git fontconfig
cd fontconfig
"%MSYS2_PATH%\bash.exe" -c "sh ./autogen.sh --prefix=%DEPS_DIR% --enable-static --disable-shared --disable-docs --disable-tests --disable-tools --disable-nls" & %check_error%
"%MSYS2_PATH%\bash.exe" -c "make -j%CPU_COUNT%" & %check_error%
"%MSYS2_PATH%\bash.exe" -c "make install" & %check_error%
cd "%SRC_DIR%"

:::: 10. libass
@REM echo Building libass
@REM git clone https://github.com/libass/libass.git libass
@REM cd libass
@REM meson setup build --prefix=%DEPS_DIR% --default-library=static --backend vs & %check_error%
@REM meson compile -C build & %check_error%
@REM meson install -C build & %check_error%
@REM cd "%SRC_DIR%"

:::: 11. libfdk-aac
@REM echo Building libfdk-aac
@REM git clone https://github.com/mstorsjo/fdk-aac.git fdk-aac
@REM cd fdk-aac
@REM cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% & %check_error%
@REM cmake --build build --config Release --target install & %check_error%
@REM cd "%SRC_DIR%"

:::: 12. libmp3lame
@REM echo Building lame
@REM git clone https://github.com/lameproject/lame.git lame
@REM cd lame
@REM "%MSYS2_PATH%\bash.exe" -c "sh ./configure --prefix=%DEPS_DIR% --enable-static --disable-shared --enable-nasm --disable-gtktest --disable-frontend" & %check_error%
@REM "%MSYS2_PATH%\bash.exe" -c "make -j%CPU_COUNT%" & %check_error%
@REM "%MSYS2_PATH%\bash.exe" -c "make install" & %check_error%
@REM cd "%SRC_DIR%"

:::: 13. libopus
@REM echo Building opus
@REM git clone https://github.com/xiph/opus.git opus
@REM cd opus
@REM cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% -DOPUS_BUILD_SHARED_LIBRARY=OFF -DOPUS_BUILD_TESTING=OFF & %check_error%
@REM cmake --build build --config Release --target install & %check_error%
@REM cd "%SRC_DIR%"

:::: 14. libogg
@REM echo Building ogg
@REM git clone https://github.com/xiph/ogg.git ogg
@REM cd ogg
@REM cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% -DINSTALL_DOCS=OFF -DBUILD_SHARED_LIBS=OFF & %check_error%
@REM cmake --build build --config Release --target install & %check_error%
@REM cd "%SRC_DIR%"

:::: 15. libvorbis
@REM echo Building vorbis
@REM git clone https://gitlab.xiph.org/xiph/vorbis.git vorbis
@REM cd vorbis
@REM cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% -DBUILD_SHARED_LIBS=OFF & %check_error%
@REM cmake --build build --config Release --target install & %check_error%
@REM cd "%SRC_DIR%"

:::: 16. libvpx
@REM echo Building libvpx
@REM git clone https://github.com/webmproject/libvpx.git libvpx
@REM cd libvpx
@REM "%MSYS2_PATH%\bash.exe" -c "sh ./configure --target=x86_64-win64-vs17 --prefix=%DEPS_DIR% --enable-static --disable-shared" & %check_error%
@REM "%MSYS2_PATH%\bash.exe" -c "make -j%CPU_COUNT%" & %check_error%
@REM "%MSYS2_PATH%\bash.exe" -c "make install" & %check_error%
@REM cd "%SRC_DIR%"

:::: 17. libx264
@REM echo Building x264
@REM git clone https://code.videolan.org/videolan/x264.git x264
@REM cd x264
@REM "%MSYS2_PATH%\bash.exe" -c "sh ./configure --prefix=%DEPS_DIR% --enable-static --disable-opencl --disable-bashcompletion --extra-cflags=\"-fPIC\"" & %check_error%
@REM "%MSYS2_PATH%\bash.exe" -c "make -j%CPU_COUNT%" & %check_error%
@REM "%MSYS2_PATH%\bash.exe" -c "make install" & %check_error%
@REM cd "%SRC_DIR%"

:::: 18. libx265
@REM echo Building x265
@REM git clone https://bitbucket.org/multicoreware/x265_git.git x265
@REM cd x265
@REM git checkout 1d117bed4747758b51bd2c124d738527e30392cb
@REM mkdir build\windows
@REM cd build\windows
@REM cmake -G "Visual Studio 17 2022" ../../source -DENABLE_SHARED=OFF -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% & %check_error%
@REM cmake --build . --config Release & %check_error%
@REM cmake --install . & %check_error%
@REM cd "%SRC_DIR%"

:::: 19. libaom
@REM echo Building libaom
@REM git clone https://aomedia.googlesource.com/aom aom
@REM mkdir aom_build
@REM cd aom_build
@REM cmake ../aom -G "Visual Studio 17 2022" -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTS=0 -DENABLE_DOCS=0 -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% & %check_error%
@REM cmake --build . --config Release & %check_error%
@REM cmake --install . & %check_error%
@REM cd "%SRC_DIR%"

:::: 20. libwebp
@REM echo Building libwebp
@REM git clone https://github.com/webmproject/libwebp.git libwebp
@REM cd libwebp
@REM cmake -G "Visual Studio 17 2022" -B build -DCMAKE_INSTALL_PREFIX=%DEPS_DIR% -DBUILD_SHARED_LIBS=OFF & %check_error%
@REM cmake --build build --config Release --target install & %check_error%
@REM cd "%SRC_DIR%"

:::: 21. libdav1d
@REM echo Building dav1d
@REM git clone https://code.videolan.org/videolan/dav1d.git dav1d
@REM cd dav1d
@REM meson setup build --prefix=%DEPS_DIR% --default-library=static --backend vs & %check_error%
@REM meson compile -C build & %check_error%
@REM meson install -C build & %check_error%
@REM cd "%SRC_DIR%"

:: Function to build FFmpeg
:build_ffmpeg
echo Building FFmpeg %1
set "VERSION=%1"
set "BRANCH=%2"
set "FFMPEG_DIR=%SRC_DIR%\ffmpeg-%VERSION%"
set "BUILD_DIR_VERSION=%BUILD_DIR%\ffmpeg-%VERSION%"
mkdir "%BUILD_DIR_VERSION%"
git clone --depth 1 --branch %BRANCH% https://github.com/FFmpeg/FFmpeg.git ffmpeg-%VERSION%
cd "%FFMPEG_DIR%"
set "CONFIGURE_CMD=./configure --toolchain=msvc --prefix=%BUILD_DIR_VERSION% --disable-static --enable-shared --pkg-config-flags=\"--static\" --extra-cflags=\"-I%DEPS_DIR%\include\" --extra-ldflags=\"-L%DEPS_DIR%\lib\" --enable-gpl --enable-asm --enable-yasm --enable-nonfree --enable-version3 --enable-openssl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libdav1d --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libaom --enable-libwebp --enable-zlib --disable-autodetect"
"%MSYS2_PATH%\bash.exe" -c "!CONFIGURE_CMD!" & %check_error%
"%MSYS2_PATH%\bash.exe" -c "make -j%CPU_COUNT%" & %check_error%
"%MSYS2_PATH%\bash.exe" -c "make install" & %check_error%
set "ARTIFACT_NAME=ffmpeg-%VERSION%-Windows-%ARCH%.tar.gz"
echo Creating artifact: %ARTIFACT_NAME%
tar -czf "%SRC_DIR%\%ARTIFACT_NAME%" -C "%BUILD_DIR_VERSION%" . & %check_error%
cd "%SRC_DIR%"
goto :eof

:: Build FFmpeg versions
@REM call :build_ffmpeg "7.1" "release/7.1"
@REM call :build_ffmpeg "6.1" "release/6.1"
@REM call :build_ffmpeg "master" "master"

echo Build completed successfully
endlocal