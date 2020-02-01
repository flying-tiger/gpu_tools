#-----------------------------------------------------------------------
# Toolchain Configuration
#-----------------------------------------------------------------------
BUILD_PREFIX   := $(realpath .)
INSTALL_PREFIX := $(realpath .)/install

CMAKE_VERSION    := 3.16.2
GCC_VERSION      := 7.5.0
CLANG_VERSION    := 8.0.1
CUDA_VERSION     := 9.2
CUDA_BUILD       := 148_396.37
EIGEN_VERSION    := master
PYBIND_VERSION   := master
CATCH_VERSION    := 2.11.1
CPPDUALS_VERSION := 0.4.1
KOKKOS_VERSION   := release-candidate-3.0

CMAKE   := ${INSTALL_PREFIX}/bin/cmake
CLANG   := ${INSTALL_PREFIX}/bin/clang
CLANGXX := ${INSTALL_PREFIX}/bin/clang++
GCC     := ${INSTALL_PREFIX}/bin/gcc
GXX     := ${INSTALL_PREFIX}/bin/g++


#-----------------------------------------------------------------------
# Alias Targets
#-----------------------------------------------------------------------
.PHONY: help
help:
	@echo "Useage:"
	@echo "  make INSTALL_PREFIX=<prefix> [target]\n"
	@echo "Targets:"
	@echo "  all       Install all software"
	@echo "  cmake     Install CMake ${CMAKE_VERSION}"
	@echo "  gcc       Install GCC ${GCC_VERSION}"
	@echo "  clang     Install Clang ${CLANG_VERSION}"
	@echo "  cuda      Install Cuda ${CUDA_VERSION}"
	@echo "  eigen     Install Eigen ${EIGEN_VERSION}"
	@echo "  pybind    Install Pybind11 ${PYBIND_VERSION}"
	@echo "  catch     Install Catch2 ${CATCH_VERSION}"
	@echo "  cppduals  Install CppDuals ${CPPDUALS_VERSION}"
	@echo "  kokkos    Install Kokkos ${KOKKOS_VERSION}"
	@echo "  clean     Remove all download/build files\n"
	@echo "Install Path:"
	@echo "  ${INSTALL_PREFIX}\n"

.PHONY: all
all: kokkos cppduals catch pybind eigen cuda clang gcc cmake

.PHONY: clean
clean: kokkos-clean cppduals-clean catch-clean pybind-clean eigen-clean \
       cuda-clean clang-clean gcc-clean cmake-clean


#-----------------------------------------------------------------------
# CMake: C++ Build System
#-----------------------------------------------------------------------

# Key Variables
CMAKE_BUILD_DIR    := ${BUILD_PREFIX}/cmake-${CMAKE_VERSION}
CMAKE_CONFIG_FILE  := ${CMAKE_BUILD_DIR}/config.done
CMAKE_BUILD_FILE   := ${CMAKE_BUILD_DIR}/build.done
CMAKE_INSTALL_FILE := ${CMAKE_BUILD_DIR}/install.done

# Shortcut Targets
.PHONY: cmake cmake-install cmake-build cmake-config cmake-clean
cmake:         ${CMAKE_INSTALL_FILE}
cmake-install: ${CMAKE_INSTALL_FILE}
cmake-build:   ${CMAKE_BUILD_FILE}
cmake-config:  ${CMAKE_CONFIG_FILE}
cmake-clean:
	rm -rf cmake-*

# Recipies
${CMAKE_INSTALL_FILE}: ${CMAKE_BUILD_FILE}
	bash cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
	  --prefix=${INSTALL_PREFIX} \
	  --skip-license && \
	  touch ${CMAKE_INSTALL_FILE}

${CMAKE_BUILD_FILE}: ${CMAKE_CONFIG_FILE}
	touch ${CMAKE_BUILD_FILE}

${CMAKE_CONFIG_FILE}:
	wget -nc https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh
	mkdir -p ${CMAKE_BUILD_DIR}
	touch ${CMAKE_CONFIG_FILE}


#-----------------------------------------------------------------------
# GCC: C++17 Standard Library
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
# Clang: GPU-Capable C++17 Compiler
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

${CLANG_CONFIG_FILE}: ${GCC_INSTALL_FILE} #${CMAKE_INSTALL_FILE}
	wget -nc https://github.com/llvm/llvm-project/archive/llvmorg-${CLANG_VERSION}.tar.gz
	tar xf llvmorg-${CLANG_VERSION}.tar.gz
	mkdir -p ${CLANG_BUILD_DIR}
	cd ${CLANG_BUILD_DIR} && ${CMAKE} ../llvm \
	  -DCMAKE_CXX_COMPILER=${GXX} \
	  -DCMAKE_C_COMPILER=${GCC} \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DLLVM_ENABLE_PROJECTS="clang;openmp"


#-----------------------------------------------------------------------
# CUDA: GPU Programming Toolkit
#-----------------------------------------------------------------------

# Key Variables
CUDA_BUILD_DIR    := ${BUILD_PREFIX}/cuda-${CUDA_VERSION}
CUDA_CONFIG_FILE  := ${CUDA_BUILD_DIR}/config.done
CUDA_BUILD_FILE   := ${CUDA_BUILD_DIR}/build.done
CUDA_INSTALL_FILE := ${CUDA_BUILD_DIR}/install.done

# Shortcut Targets
.PHONY: cuda cuda-install cuda-build cuda-config cuda-clean
cuda:         ${CUDA_INSTALL_FILE}
cuda-install: ${CUDA_INSTALL_FILE}
cuda-build:   ${CUDA_BUILD_FILE}
cuda-config:  ${CUDA_CONFIG_FILE}
cuda-clean:
	rm -rf cuda-*

# Recipies
${CUDA_INSTALL_FILE}: ${CUDA_BUILD_FILE}
	bash cuda_${CUDA_VERSION}.${CUDA_BUILD}_linux \
	  --silent \
	  --toolkit \
	  --toolkitpath=${INSTALL_PREFIX}/cuda-${CUDA_VERSION} && \
	  touch ${CUDA_INSTALL_FILE}

${CUDA_BUILD_FILE}: ${CUDA_CONFIG_FILE}
	touch ${CUDA_BUILD_FILE}

${CUDA_CONFIG_FILE}:
	wget -nc https://developer.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod2/local_installers/cuda_${CUDA_VERSION}.${CUDA_BUILD}_linux
	mkdir -p ${CUDA_BUILD_DIR}
	touch ${CUDA_CONFIG_FILE}


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
	cd ${EIGEN_BUILD_DIR} && ${CMAKE} .. \
	  -DCMAKE_CXX_COMPILER=${CLANGXX} \
	  -DCMAKE_C_COMPILER=${CLANG} \
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

${PYBIND_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	wget -nc https://github.com/pybind/pybind11/archive/${PYBIND_VERSION}.tar.gz
	tar xf ${PYBIND_VERSION}.tar.gz
	mkdir -p ${PYBIND_BUILD_DIR}
	cd ${PYBIND_BUILD_DIR} && ${CMAKE} .. \
	  -DCMAKE_CXX_COMPILER=${CLANGXX} \
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
	cd ${CATCH_BUILD_DIR} && ${CMAKE} .. \
	  -DCMAKE_CXX_COMPILER=${CLANGXX} \
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
	  -DCMAKE_CXX_COMPILER=${CLANGXX} \
	  -DCMAKE_C_COMPILER=${CLANG} \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release


#-----------------------------------------------------------------------
# Kokkos: C++ CPU/GPU Abstraction Layer
#-----------------------------------------------------------------------

# Key Variables
KOKKOS_BUILD_DIR    := ${BUILD_PREFIX}/kokkos-${KOKKOS_VERSION}/build
KOKKOS_CONFIG_FILE  := ${KOKKOS_BUILD_DIR}/config.done
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

${KOKKOS_CONFIG_FILE}: ${CLANG_INSTALL_FILE} ${CUDA_INSTALL_FILE}
	wget -nc https://github.com/flying-tiger/kokkos/archive/${KOKKOS_VERSION}.tar.gz
	tar xf ${KOKKOS_VERSION}.tar.gz
	mkdir -p ${KOKKOS_BUILD_DIR}
	cd ${KOKKOS_BUILD_DIR} && ${CMAKE} .. \
	  -DCMAKE_CXX_COMPILER=${CLANGXX} \
	  -DCMAKE_CXX_FLAGS="--cuda-path=${INSTALL_PREFIX}/cuda-${CUDA_VERSION}" \
	  -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DKokkos_ARCH_SKX=ON       \
	  -DKokkos_ARCH_VOLTA70=ON   \
	  -DKokkos_ENABLE_SERIAL=ON  \
	  -DKokkos_ENABLE_OPENMP=ON  \
	  -DKokkos_ENABLE_CUDA=ON    \
	  -DKokkos_ENABLE_CUDA_LAMBDA=ON \
	  -DKokkos_ENABLE_CUDA_CONSTEXPR=ON \
	  -DKokkos_CUDA_DIR=${INSTALL_PREFIX}/cuda-${CUDA_VERSION} && \
	touch ${KOKKOS_CONFIG_FILE}

