#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Override compiler and archiver on a platform specific basis as, by default, the build
# of luamake is setup to use "cc" and "ar" on Linux.
# cf.: https://github.com/actboy168/luamake/blob/master/compile/ninja/linux.ninja
LUAMAKE_NINJA_OPTS=""
if [[ ${target_platform} =~ .*linux.* ]]; then
    if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
      LUAMAKE_NINJA_OPTS="-Dcc=${BUILD}-gcc -Dar=${BUILD}-ar"
    else
      LUAMAKE_NINJA_OPTS="-Dcc=${CC} -Dar=${AR}"
    fi
fi
pushd 3rd/luamake
compile/build.sh ${LUAMAKE_NINJA_OPTS} notest
popd

# Use just built luamake to compile the language server
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
