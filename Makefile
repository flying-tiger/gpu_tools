#-----------------------------------------------------------------------
# Toolchain Configuration
#-----------------------------------------------------------------------
INSTALL_PREFIX := /swbuild/tsa/apps/gpu_tools/1.0

GCC_VERSION   := 7.5.0
CLANG_VERSION := 8.0.1


#-----------------------------------------------------------------------
# GCC: Provides C++17 libstdc++
#-----------------------------------------------------------------------

# Key Variables
GCC_BUILD_DIR    := gcc-${GCC_VERSION}/build
GCC_CONFIG_FILE  := ${GCC_BUILD_DIR}/config.log
GCC_BUILD_FILE   := ${GCC_BUILD_DIR}/gcc/libgcc.a
GCC_INSTALL_FILE := ${INSTALL_PREFIX}/bin/g++

# Shortcut Targets
.PHONY: gcc gcc-install gcc-build gcc-config gcc-clean
gcc:         ${GCC_INSTALL_FILE}
gcc-install: ${GCC_INSTALL_FILE}
gcc-build:   ${GCC_BUILD_FILE}
gcc-config:  ${GCC_CONFIG_FILE}
gcc-clean:
	rm -rf gcc-*

# Recipies
${GCC_INSTALL_FILE}: ${GCC_BUILD_FILE}
	cd ${GCC_BUILD_DIR} && make install

${GCC_BUILD_FILE}: ${GCC_CONFIG_FILE}
	cd ${GCC_BUILD_DIR} && make -j4

${GCC_CONFIG_FILE}:
	wget -nc https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz
	tar xf gcc-${GCC_VERSION}.tar.xz
	cd gcc-${GCC_VERSION} && ./contrib/download_prerequisites
	mkdir -p ${GCC_BUILD_DIR}
	cd ${GCC_BUILD_DIR} && ../configure \
	  --prefix=${INSTALL_PREFIX} \
	  --enable-languages=c,c++,fortran \
	  --disable-multilib


#-----------------------------------------------------------------------
# Clang: Provides C++17 compiler (GPU-capable)
#-----------------------------------------------------------------------

# Key Variables
CLANG_BUILD_DIR    := llvm-project-llvmorg-${CLANG_VERSION}/build
CLANG_CONFIG_FILE  := ${CLANG_BUILD_DIR}/CMakeCache.txt
CLANG_BUILD_FILE   := ${CLANG_BUILD_DIR}/bin/clang-8
CLANG_INSTALL_FILE := ${INSTALL_PREFIX}/bin/clang++

# Shortcut Targets
.PHONY: clang clang-install clang-build clang-config clang-clean
clang:         ${CLANG_INSTALL_FILE}
clang-install: ${CLANG_INSTALL_FILE}
clang-build:   ${CLANG_BUILD_FILE}
clang-config:  ${CLANG_CONFIG_FILE}
clang-clean:
	rm -rf clang-*

# Recipies
${CLANG_INSTALL_FILE}: ${CLANG_BUILD_FILE}
	cd ${CLANG_BUILD_DIR} && make install

${CLANG_BUILD_FILE}: ${CLANG_CONFIG_FILE}
	cd ${CLANG_BUILD_DIR} && make -j4

${CLANG_CONFIG_FILE}: ${GCC_INSTALL_FILE}
	#wget -nc https://github.com/llvm/llvm-project/archive/llvmorg-${CLANG_VERSION}.tar.gz
	#tar xf llvmorg-${CLANG_VERSION}.tar.gz
	mkdir -p ${CLANG_BUILD_DIR}
	cd ${CLANG_BUILD_DIR} && cmake ../llvm \
	  -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/g++ \
	  -DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/gcc \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DLLVM_ENABLE_PROJECTS="clang;openmp"



