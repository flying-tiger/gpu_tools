#-----------------------------------------------------------------------
# Toolchain Configuration
#-----------------------------------------------------------------------
BUILD_PREFIX   := $(realpath .)
INSTALL_PREFIX := /swbuild/tsa/apps/gpu_tools/1.0


GCC_VERSION      := 7.5.0
CLANG_VERSION    := 8.0.1
EIGEN_VERSION    := 3.3.7
PYBIND_VERSION   := 2.4.3
CATCH_VERSION    := 2.11.1
CPPDUALS_VERSION := 0.4.1
KOKKOS_VERSION   := release-candidate-3.0


#-----------------------------------------------------------------------
# GCC: Provides C++17 libstdc++
#-----------------------------------------------------------------------

# Key Variables
GCC_BUILD_DIR    := ${BUILD_PREFIX}/gcc-${GCC_VERSION}/build
GCC_CONFIG_FILE  := ${GCC_BUILD_DIR}/config.log
GCC_BUILD_FILE   := ${GCC_BUILD_DIR}/build.done
GCC_INSTALL_FILE := ${GCC_BUILD_DIR}/install.done

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
	cd ${GCC_BUILD_DIR} && make -j4 install && touch ${GCC_INSTALL_FILE}

${GCC_BUILD_FILE}: ${GCC_CONFIG_FILE}
	cd ${GCC_BUILD_DIR} && make -j4 && touch ${GCC_BUILD_FILE}

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
CLANG_BUILD_DIR    := ${BUILD_PREFIX}/llvm-project-llvmorg-${CLANG_VERSION}/build
CLANG_CONFIG_FILE  := ${CLANG_BUILD_DIR}/CMakeCache.txt
CLANG_BUILD_FILE   := ${CLANG_BUILD_DIR}/build.done
CLANG_INSTALL_FILE := ${CLANG_BUILD_DIR}/install.done

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
	cd ${CLANG_BUILD_DIR} && make -j4 install && touch ${CLANG_INSTALL_FILE}

${CLANG_BUILD_FILE}: ${CLANG_CONFIG_FILE}
	cd ${CLANG_BUILD_DIR} && make -j4 && touch ${CLANG_BUILD_FILE}

${CLANG_CONFIG_FILE}: ${GCC_INSTALL_FILE}
	wget -nc https://github.com/llvm/llvm-project/archive/llvmorg-${CLANG_VERSION}.tar.gz
	tar xf llvmorg-${CLANG_VERSION}.tar.gz
	mkdir -p ${CLANG_BUILD_DIR}
	cd ${CLANG_BUILD_DIR} && cmake ../llvm \
	  -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/g++ \
	  -DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/gcc \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DLLVM_ENABLE_PROJECTS="clang;openmp"


#-----------------------------------------------------------------------
# Eigen: GPU-Capabile Linear Algebra Library
#-----------------------------------------------------------------------

# Key Variables
EIGEN_BUILD_DIR    := ${BUILD_PREFIX}/eigen-${EIGEN_VERSION}/build
EIGEN_CONFIG_FILE  := ${EIGEN_BUILD_DIR}/CMakeCache.txt
EIGEN_BUILD_FILE   := ${EIGEN_BUILD_DIR}/build.done
EIGEN_INSTALL_FILE := ${EIGEN_BUILD_DIR}/install.done

# Shortcut Targets
.PHONY: eigen eigen-install eigen-build eigen-config eigen-clean
eigen:         ${EIGEN_INSTALL_FILE}
eigen-install: ${EIGEN_INSTALL_FILE}
eigen-build:   ${EIGEN_BUILD_FILE}
eigen-config:  ${EIGEN_CONFIG_FILE}
eigen-clean:
	rm -rf eigen-*

# Recipies
${EIGEN_INSTALL_FILE}: ${EIGEN_BUILD_FILE}
	cd ${EIGEN_BUILD_DIR} && make -j4 install && touch ${EIGEN_INSTALL_FILE}

${EIGEN_BUILD_FILE}: ${EIGEN_CONFIG_FILE}
	cd ${EIGEN_BUILD_DIR} && make -j4 && touch ${EIGEN_BUILD_FILE}

${EIGEN_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	wget -nc https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_VERSION}/eigen-${EIGEN_VERSION}.tar.gz
	tar xf eigen-${EIGEN_VERSION}.tar.gz
	mkdir -p ${EIGEN_BUILD_DIR}
	cd ${EIGEN_BUILD_DIR} && cmake .. \
	  -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
	  -DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/clang \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release


#-----------------------------------------------------------------------
# Pybind: Call C++ Code from Python
#-----------------------------------------------------------------------

# Key Variables
PYBIND_BUILD_DIR    := ${BUILD_PREFIX}/pybind11-${PYBIND_VERSION}/build
PYBIND_CONFIG_FILE  := ${PYBIND_BUILD_DIR}/CMakeCache.txt
PYBIND_BUILD_FILE   := ${PYBIND_BUILD_DIR}/build.done
PYBIND_INSTALL_FILE := ${PYBIND_BUILD_DIR}/install.done

# Shortcut Targets
.PHONY: pybind pybind-install pybind-build pybind-config pybind-clean
pybind:         ${PYBIND_INSTALL_FILE}
pybind-install: ${PYBIND_INSTALL_FILE}
pybind-build:   ${PYBIND_BUILD_FILE}
pybind-config:  ${PYBIND_CONFIG_FILE}
pybind-clean:
	rm -rf pybind-*

# Recipies
${PYBIND_INSTALL_FILE}: ${PYBIND_BUILD_FILE}
	cd ${PYBIND_BUILD_DIR} && make -j4 install && touch ${PYBIND_INSTALL_FILE}

${PYBIND_BUILD_FILE}: ${PYBIND_CONFIG_FILE}
	cd ${PYBIND_BUILD_DIR} && make -j4 && touch ${PYBIND_BUILD_FILE}

${PYBIND_CONFIG_FILE}: ${EIGEN_INSTALL_FILE}
	wget -nc https://github.com/pybind/pybind11/archive/v${PYBIND_VERSION}.tar.gz
	tar xf v${PYBIND_VERSION}.tar.gz
	mkdir -p ${PYBIND_BUILD_DIR}
	cd ${PYBIND_BUILD_DIR} && cmake .. \
	  -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DPYBIND11_TEST=OFF


#-----------------------------------------------------------------------
# Catch: C++ Unit Test Framework
#-----------------------------------------------------------------------

# Key Variables
CATCH_BUILD_DIR    := ${BUILD_PREFIX}/Catch2-${CATCH_VERSION}/build
CATCH_CONFIG_FILE  := ${CATCH_BUILD_DIR}/CMakeCache.txt
CATCH_BUILD_FILE   := ${CATCH_BUILD_DIR}/build.done
CATCH_INSTALL_FILE := ${CATCH_BUILD_DIR}/install.done

# Shortcut Targets
.PHONY: catch catch-install catch-build catch-config catch-clean
catch:         ${CATCH_INSTALL_FILE}
catch-install: ${CATCH_INSTALL_FILE}
catch-build:   ${CATCH_BUILD_FILE}
catch-config:  ${CATCH_CONFIG_FILE}
catch-clean:
	rm -rf catch-*

# Recipies
${CATCH_INSTALL_FILE}: ${CATCH_BUILD_FILE}
	cd ${CATCH_BUILD_DIR} && make -j4 install && touch ${CATCH_INSTALL_FILE}

${CATCH_BUILD_FILE}: ${CATCH_CONFIG_FILE}
	cd ${CATCH_BUILD_DIR} && make -j4 && touch ${CATCH_BUILD_FILE}

${CATCH_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	wget -nc https://github.com/catchorg/Catch2/archive/v${CATCH_VERSION}.tar.gz
	tar xf v${CATCH_VERSION}.tar.gz
	mkdir -p ${CATCH_BUILD_DIR}
	cd ${CATCH_BUILD_DIR} && cmake .. \
	  -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DBUILD_TESTING=OFF


#-----------------------------------------------------------------------
# CppDuals: C++ Automatic Differentiation Library
#-----------------------------------------------------------------------

# Key Variables
CPPDUALS_BUILD_DIR    := ${BUILD_PREFIX}/cppduals-v${CPPDUALS_VERSION}/build
CPPDUALS_CONFIG_FILE  := ${CPPDUALS_BUILD_DIR}/CMakeCache.txt
CPPDUALS_BUILD_FILE   := ${CPPDUALS_BUILD_DIR}/build.done
CPPDUALS_INSTALL_FILE := ${CPPDUALS_BUILD_DIR}/install.done

# Shortcut Targets
.PHONY: cppduals cppduals-install cppduals-build cppduals-config cppduals-clean
cppduals:         ${CPPDUALS_INSTALL_FILE}
cppduals-install: ${CPPDUALS_INSTALL_FILE}
cppduals-build:   ${CPPDUALS_BUILD_FILE}
cppduals-config:  ${CPPDUALS_CONFIG_FILE}
cppduals-clean:
	rm -rf cppduals-*

# Recipies
${CPPDUALS_INSTALL_FILE}: ${CPPDUALS_BUILD_FILE}
	cd ${CPPDUALS_BUILD_DIR} && make -j4 install && touch ${CPPDUALS_INSTALL_FILE}

${CPPDUALS_BUILD_FILE}: ${CPPDUALS_CONFIG_FILE}
	cd ${CPPDUALS_BUILD_DIR} && make -j4 && touch ${CPPDUALS_BUILD_FILE}

${CPPDUALS_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	wget -nc https://gitlab.com/tesch1/cppduals/-/archive/v${CPPDUALS_VERSION}/cppduals-v${CPPDUALS_VERSION}.tar.gz
	tar xf cppduals-v${CPPDUALS_VERSION}.tar.gz
	mkdir -p ${CPPDUALS_BUILD_DIR}
	cd ${CPPDUALS_BUILD_DIR} && cmake .. \
	  -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
	  -DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/clang \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release


#-----------------------------------------------------------------------
# Kokkos: C++ CPU/GPU Abstraction Layer
#-----------------------------------------------------------------------

# Key Variables
KOKKOS_BUILD_DIR    := ${BUILD_PREFIX}/kokkos-${KOKKOS_VERSION}/build
KOKKOS_CONFIG_FILE  := ${KOKKOS_BUILD_DIR}/CMakeCache.txt
KOKKOS_BUILD_FILE   := ${KOKKOS_BUILD_DIR}/build.done
KOKKOS_INSTALL_FILE := ${KOKKOS_BUILD_DIR}/install.done

# Shortcut Targets
.PHONY: kokkos kokkos-install kokkos-build kokkos-config kokkos-clean
kokkos:         ${KOKKOS_INSTALL_FILE}
kokkos-install: ${KOKKOS_INSTALL_FILE}
kokkos-build:   ${KOKKOS_BUILD_FILE}
kokkos-config:  ${KOKKOS_CONFIG_FILE}
kokkos-clean:
	rm -rf kokkos-*

# Recipies
${KOKKOS_INSTALL_FILE}: ${KOKKOS_BUILD_FILE}
	cd ${KOKKOS_BUILD_DIR} && make -j4 install && touch ${KOKKOS_INSTALL_FILE}

${KOKKOS_BUILD_FILE}: ${KOKKOS_CONFIG_FILE}
	cd ${KOKKOS_BUILD_DIR} && make -j4 && touch ${KOKKOS_BUILD_FILE}

${KOKKOS_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	wget -nc https://github.com/kokkos/kokkos/archive/${KOKKOS_VERSION}.tar.gz
	tar xf ${KOKKOS_VERSION}.tar.gz
	mkdir -p ${KOKKOS_BUILD_DIR}
	cd ${KOKKOS_BUILD_DIR} && cmake .. \
	  -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
	  -DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/clang \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DKokkos_ARCH_SKX=ON       \
	  -DKokkos_ARCH_VOLTA70=ON   \
	  -DKokkos_ENABLE_SERIAL=ON  \
	  -DKokkos_ENABLE_OPENMP=ON  \
	  -DKokkos_ENABLE_CUDA=ON    \
	  -DKokkos_ENABLE_CUDA_LAMBDA=ON \
	  -DKokkos_ENABLE_CUDA_CONSTEXPR=ON

