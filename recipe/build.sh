#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Create symlinks on Linux because gcc/g++/ar are hardcoded for luamake build
# cf.: https://github.com/actboy168/luamake/blob/master/compile/ninja/linux.ninja
if [[ ${target_platform} =~ .*linux.* ]]; then
    if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
      ln -sf ${BUILD_PREFIX}/bin/${BUILD}-gcc ${BUILD_PREFIX}/bin/gcc
      ln -sf ${BUILD_PREFIX}/bin/${BUILD}-ar ${BUILD_PREFIX}/bin/ar
    else
      ln -sf ${CC} ${BUILD_PREFIX}/bin/gcc
      ln -sf ${AR} ${BUILD_PREFIX}/bin/ar
    fi
fi

pushd 3rd/luamake
compile/build.sh notest
popd

3rd/luamake/luamake -cc "$CC" -ar "$AR" -cflags "$CFLAGS" rebuild -notest

mkdir -p ${PREFIX}/libexec/${PKG_NAME}
mkdir -p ${PREFIX}/libexec/${PKG_NAME}/bin
mkdir -p ${PREFIX}/libexec/${PKG_NAME}/log
mkdir -p ${PREFIX}/bin

install -m 755 bin/${PKG_NAME} ${PREFIX}/libexec/${PKG_NAME}/bin
install -m 755 bin/main.lua ${PREFIX}/libexec/${PKG_NAME}/bin
install -m 644 main.lua ${PREFIX}/libexec/${PKG_NAME}
install -m 644 debugger.lua ${PREFIX}/libexec/${PKG_NAME}
cp -r locale ${PREFIX}/libexec/${PKG_NAME}
cp -r meta ${PREFIX}/libexec/${PKG_NAME}
cp -r script ${PREFIX}/libexec/${PKG_NAME}
cp changelog.md ${PREFIX}/libexec/${PKG_NAME}

# As per recommendation at https://luals.github.io/#other-install
tee ${PKG_NAME} <<EOF
#!/bin/sh
exec ${PREFIX}/libexec/${PKG_NAME}/bin/${PKG_NAME} "\$@"
EOF

install -m 755 ${PKG_NAME} ${PREFIX}/bin
