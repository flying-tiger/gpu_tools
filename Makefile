#-----------------------------------------------------------------------
# Toolchain Configuration
#-----------------------------------------------------------------------
BUILD_PREFIX   := $(realpath .)/build
INSTALL_PREFIX := $(realpath .)/install

CMAKE_VERSION    := 3.16.2
GCC_VERSION      := 7.5.0
CLANG_VERSION    := 8.0.1
CUDA_VERSION     := 9.2
CUDA_BUILD       := 148_396.37
EIGEN_VERSION    := master
PYBIND_VERSION   := 2.5.0
CATCH_VERSION    := 2.11.1
CPPDUALS_VERSION := 0.4.1
AUTODIFF_VERSION := 0.5.10
KOKKOS_VERSION   := 3.1.00

CMAKE   := ${INSTALL_PREFIX}/bin/cmake
CLANG   := ${INSTALL_PREFIX}/bin/clang
CLANGXX := ${INSTALL_PREFIX}/bin/clang++
GCC     := ${INSTALL_PREFIX}/bin/gcc
GXX     := ${INSTALL_PREFIX}/bin/g++

NJOBS   := 4


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
	@echo "  autodiff  Install AutoDiff ${AUTODIFF_VERSION}"
	@echo "  kokkos    Install Kokkos ${KOKKOS_VERSION}"
	@echo "  clean     Remove all download/build files\n"
	@echo "Install Path:"
	@echo "  ${INSTALL_PREFIX}\n"

.PHONY: all
all: kokkos cppduals autodiff catch pybind eigen cuda clang gcc cmake

.PHONY: clean
clean:
	rm -rf ${BUILD_PREFIX}


#-----------------------------------------------------------------------
# CMake: C++ Build System
#-----------------------------------------------------------------------

# Key Variables
CMAKE_BASE_DIR     := ${BUILD_PREFIX}/cmake
CMAKE_CONFIG_FILE  := ${CMAKE_BASE_DIR}/config.done
CMAKE_BUILD_FILE   := ${CMAKE_BASE_DIR}/build.done
CMAKE_INSTALL_FILE := ${CMAKE_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: cmake cmake-install cmake-build cmake-config cmake-clean
cmake:         ${CMAKE_INSTALL_FILE}
cmake-install: ${CMAKE_INSTALL_FILE}
cmake-build:   ${CMAKE_BUILD_FILE}
cmake-config:  ${CMAKE_CONFIG_FILE}
cmake-clean:
	rm -rf ${CMAKE_BASE_DIR}

# Recipies
${CMAKE_INSTALL_FILE}: ${CMAKE_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${CMAKE_BASE_DIR} && bash cmake.sh \
	    --prefix=${INSTALL_PREFIX} \
	    --skip-license
	touch ${CMAKE_INSTALL_FILE}

${CMAKE_BUILD_FILE}: ${CMAKE_CONFIG_FILE}
	touch ${CMAKE_BUILD_FILE}

${CMAKE_CONFIG_FILE}:
	mkdir -p ${CMAKE_BASE_DIR}
	wget -nc -O ${CMAKE_BASE_DIR}/cmake.sh \
	    https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
	    || true
	touch ${CMAKE_CONFIG_FILE}


#-----------------------------------------------------------------------
# GCC: C++17 Standard Library
#-----------------------------------------------------------------------

# Key Variables
GCC_BASE_DIR     := ${BUILD_PREFIX}/gcc
GCC_BUILD_DIR    := ${GCC_BASE_DIR}/build
GCC_CONFIG_FILE  := ${GCC_BASE_DIR}/config.done
GCC_BUILD_FILE   := ${GCC_BASE_DIR}/build.done
GCC_INSTALL_FILE := ${GCC_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: gcc gcc-install gcc-build gcc-config gcc-clean
gcc:         ${GCC_INSTALL_FILE}
gcc-install: ${GCC_INSTALL_FILE}
gcc-build:   ${GCC_BUILD_FILE}
gcc-config:  ${GCC_CONFIG_FILE}
gcc-clean:
	rm -rf ${GCC_BASE_DIR}

# Recipies
${GCC_INSTALL_FILE}: ${GCC_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${GCC_BUILD_DIR} && make -j${NJOBS} install
	touch ${GCC_INSTALL_FILE}

${GCC_BUILD_FILE}: ${GCC_CONFIG_FILE}
	cd ${GCC_BUILD_DIR} && make -j${NJOBS}
	touch ${GCC_BUILD_FILE}

${GCC_CONFIG_FILE}:
	mkdir -p ${GCC_BASE_DIR} ${GCC_BUILD_DIR}
	wget -nc -O ${GCC_BASE_DIR}/gcc.tar.xz \
	    https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz \
	    || true
	cd ${GCC_BASE_DIR} && tar xf gcc.tar.xz --strip-components 1
	cd ${GCC_BASE_DIR} && ./contrib/download_prerequisites
	cd ${GCC_BUILD_DIR} && ../configure \
	    --prefix=${INSTALL_PREFIX} \
	    --enable-languages=c,c++,fortran \
	    --disable-multilib
	touch ${GCC_CONFIG_FILE}


#-----------------------------------------------------------------------
# Clang: GPU-Capable C++17 Compiler
#-----------------------------------------------------------------------

# Key Variables
CLANG_BASE_DIR     := ${BUILD_PREFIX}/clang
CLANG_BUILD_DIR    := ${CLANG_BASE_DIR}/build
CLANG_CONFIG_FILE  := ${CLANG_BASE_DIR}/config.done
CLANG_BUILD_FILE   := ${CLANG_BASE_DIR}/build.done
CLANG_INSTALL_FILE := ${CLANG_BASE_DIR}/install.done
ifneq (,$(wildcard /usr/include/plugin-api.h))
    CLANG_WITH_GOLD := -DLLVM_BINUTILS_INCDIR=/usr/include
else
    CLANG_WITH_GOLD :=
endif

# Shortcut Targets
.PHONY: clang clang-install clang-build clang-config clang-clean
clang:         ${CLANG_INSTALL_FILE}
clang-install: ${CLANG_INSTALL_FILE}
clang-build:   ${CLANG_BUILD_FILE}
clang-config:  ${CLANG_CONFIG_FILE}
clang-clean:
	rm -rf ${CLANG_BASE_DIR}

# Recipies
${CLANG_INSTALL_FILE}: ${CLANG_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${CLANG_BUILD_DIR} && make -j${NJOBS} install
	touch ${CLANG_INSTALL_FILE}

${CLANG_BUILD_FILE}: ${CLANG_CONFIG_FILE}
	cd ${CLANG_BUILD_DIR} && make -j${NJOBS}
	touch ${CLANG_BUILD_FILE}

${CLANG_CONFIG_FILE}: # ${GCC_INSTALL_FILE} ${CMAKE_INSTALL_FILE}
	mkdir -p ${CLANG_BASE_DIR} ${CLANG_BUILD_DIR}
	wget -nc -O ${CLANG_BASE_DIR}/clang.tar.gz \
	    https://github.com/llvm/llvm-project/archive/llvmorg-${CLANG_VERSION}.tar.gz \
	    || true
	cd ${CLANG_BASE_DIR} && tar xf clang.tar.gz --strip-components 1
	cd ${CLANG_BUILD_DIR} && ${CMAKE} ../llvm \
	    -DCMAKE_CXX_COMPILER=${GXX} \
	    -DCMAKE_C_COMPILER=${GCC} \
	    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DLLVM_ENABLE_PROJECTS="clang;openmp" \
	    ${CLANG_WITH_GOLD}
	touch ${CLANG_CONFIG_FILE}


#-----------------------------------------------------------------------
# CUDA: GPU Programming Toolkit
#-----------------------------------------------------------------------

# Key Variables
CUDA_BASE_DIR     := ${BUILD_PREFIX}/cuda
CUDA_CONFIG_FILE  := ${CUDA_BASE_DIR}/config.done
CUDA_BUILD_FILE   := ${CUDA_BASE_DIR}/build.done
CUDA_INSTALL_FILE := ${CUDA_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: cuda cuda-install cuda-build cuda-config cuda-clean
cuda:         ${CUDA_INSTALL_FILE}
cuda-install: ${CUDA_INSTALL_FILE}
cuda-build:   ${CUDA_BUILD_FILE}
cuda-config:  ${CUDA_CONFIG_FILE}
cuda-clean:
	rm -rf ${CUDA_BASE_DIR}

# Recipies
${CUDA_INSTALL_FILE}: ${CUDA_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${CUDA_BASE_DIR} && bash cuda.sh \
	    --silent \
	    --toolkit \
	    --toolkitpath=${INSTALL_PREFIX}/cuda-${CUDA_VERSION}
	touch ${CUDA_INSTALL_FILE}

${CUDA_BUILD_FILE}: ${CUDA_CONFIG_FILE}
	touch ${CUDA_BUILD_FILE}

${CUDA_CONFIG_FILE}:
	mkdir -p ${CUDA_BASE_DIR}
	wget -nc -O ${CUDA_BASE_DIR}/cuda.sh \
	    https://developer.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod2/local_installers/cuda_${CUDA_VERSION}.${CUDA_BUILD}_linux \
	    || true
	touch ${CUDA_CONFIG_FILE}


#-----------------------------------------------------------------------
# Eigen: GPU-Capabile Linear Algebra Library
#-----------------------------------------------------------------------

# Key Variables
EIGEN_BASE_DIR     := ${BUILD_PREFIX}/eigen
EIGEN_BUILD_DIR    := ${EIGEN_BASE_DIR}/build
EIGEN_CONFIG_FILE  := ${EIGEN_BASE_DIR}/config.done
EIGEN_BUILD_FILE   := ${EIGEN_BASE_DIR}/build.done
EIGEN_INSTALL_FILE := ${EIGEN_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: eigen eigen-install eigen-build eigen-config eigen-clean
eigen:         ${EIGEN_INSTALL_FILE}
eigen-install: ${EIGEN_INSTALL_FILE}
eigen-build:   ${EIGEN_BUILD_FILE}
eigen-config:  ${EIGEN_CONFIG_FILE}
eigen-clean:
	rm -rf ${EIGEN_BASE_DIR}

# Recipies
${EIGEN_INSTALL_FILE}: ${EIGEN_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${EIGEN_BUILD_DIR} && make -j${NJOBS} install
	touch ${EIGEN_INSTALL_FILE}

${EIGEN_BUILD_FILE}: ${EIGEN_CONFIG_FILE}
	cd ${EIGEN_BUILD_DIR} && make -j${NJOBS}
	touch ${EIGEN_BUILD_FILE}

${EIGEN_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	mkdir -p ${EIGEN_BASE_DIR} ${EIGEN_BUILD_DIR}
	wget -nc -O ${EIGEN_BASE_DIR}/eigen.tar.gz \
	    https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_VERSION}/eigen-${EIGEN_VERSION}.tar.gz \
	    || true
	cd ${EIGEN_BASE_DIR} && tar xf eigen.tar.gz --strip-components 1
	cd ${EIGEN_BUILD_DIR} && ${CMAKE} .. \
	    -DCMAKE_CXX_COMPILER=${CLANGXX} \
	    -DCMAKE_C_COMPILER=${CLANG} \
	    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	    -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	    -DCMAKE_BUILD_TYPE=Release
	touch ${EIGEN_CONFIG_FILE}


#-----------------------------------------------------------------------
# Pybind: Call C++ Code from Python
#-----------------------------------------------------------------------

# Key Variables
PYBIND_BASE_DIR     := ${BUILD_PREFIX}/pybind
PYBIND_BUILD_DIR    := ${PYBIND_BASE_DIR}/build
PYBIND_CONFIG_FILE  := ${PYBIND_BASE_DIR}/config.done
PYBIND_BUILD_FILE   := ${PYBIND_BASE_DIR}/build.done
PYBIND_INSTALL_FILE := ${PYBIND_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: pybind pybind-install pybind-build pybind-config pybind-clean
pybind:         ${PYBIND_INSTALL_FILE}
pybind-install: ${PYBIND_INSTALL_FILE}
pybind-build:   ${PYBIND_BUILD_FILE}
pybind-config:  ${PYBIND_CONFIG_FILE}
pybind-clean:
	rm -rf ${PYBIND_BASE_DIR}

# Recipies
${PYBIND_INSTALL_FILE}: ${PYBIND_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${PYBIND_BUILD_DIR} && make -j${NJOBS} install
	touch ${PYBIND_INSTALL_FILE}

${PYBIND_BUILD_FILE}: ${PYBIND_CONFIG_FILE}
	cd ${PYBIND_BUILD_DIR} && make -j${NJOBS}
	touch ${PYBIND_BUILD_FILE}

${PYBIND_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	mkdir -p ${PYBIND_BASE_DIR} ${PYBIND_BUILD_DIR}
	wget -nc -O ${PYBIND_BASE_DIR}/pybind.tar.gz \
	    https://github.com/pybind/pybind11/archive/v${PYBIND_VERSION}.tar.gz \
	    || true
	cd ${PYBIND_BASE_DIR} && tar xf pybind.tar.gz --strip-components 1
	cd ${PYBIND_BUILD_DIR} && ${CMAKE} .. \
	    -DCMAKE_CXX_COMPILER=${CLANGXX} \
	    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	    -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DPYBIND11_TEST=OFF
	touch ${PYBIND_CONFIG_FILE}


#-----------------------------------------------------------------------
# Catch: C++ Unit Test Framework
#-----------------------------------------------------------------------

# Key Variables
CATCH_BASE_DIR     := ${BUILD_PREFIX}/catch
CATCH_BUILD_DIR    := ${CATCH_BASE_DIR}/build
CATCH_CONFIG_FILE  := ${CATCH_BASE_DIR}/config.done
CATCH_BUILD_FILE   := ${CATCH_BASE_DIR}/build.done
CATCH_INSTALL_FILE := ${CATCH_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: catch catch-install catch-build catch-config catch-clean
catch:         ${CATCH_INSTALL_FILE}
catch-install: ${CATCH_INSTALL_FILE}
catch-build:   ${CATCH_BUILD_FILE}
catch-config:  ${CATCH_CONFIG_FILE}
catch-clean:
	rm -rf ${CATCH_BASE_DIR}

# Recipies
${CATCH_INSTALL_FILE}: ${CATCH_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${CATCH_BUILD_DIR} && make -j${NJOBS} install
	touch ${CATCH_INSTALL_FILE}

${CATCH_BUILD_FILE}: ${CATCH_CONFIG_FILE}
	cd ${CATCH_BUILD_DIR} && make -j${NJOBS}
	touch ${CATCH_BUILD_FILE}

${CATCH_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	mkdir -p ${CATCH_BASE_DIR} ${CATCH_BUILD_DIR}
	wget -nc -O ${CATCH_BASE_DIR}/catch.tar.gz \
	    https://github.com/catchorg/Catch2/archive/v${CATCH_VERSION}.tar.gz \
	    || true
	cd ${CATCH_BASE_DIR} && tar xf catch.tar.gz --strip-components 1
	cd ${CATCH_BUILD_DIR} && ${CMAKE} .. \
	    -DCMAKE_CXX_COMPILER=${CLANGXX} \
	    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	    -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DBUILD_TESTING=OFF
	touch ${CATCH_CONFIG_FILE}


#-----------------------------------------------------------------------
# CppDuals: C++ Automatic Differentiation Library
#-----------------------------------------------------------------------

# Key Variables
CPPDUALS_BASE_DIR     := ${BUILD_PREFIX}/cppduals
CPPDUALS_BUILD_DIR    := ${CPPDUALS_BASE_DIR}/build
CPPDUALS_CONFIG_FILE  := ${CPPDUALS_BASE_DIR}/config.done
CPPDUALS_BUILD_FILE   := ${CPPDUALS_BASE_DIR}/build.done
CPPDUALS_INSTALL_FILE := ${CPPDUALS_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: cppduals cppduals-install cppduals-build cppduals-config cppduals-clean
cppduals:         ${CPPDUALS_INSTALL_FILE}
cppduals-install: ${CPPDUALS_INSTALL_FILE}
cppduals-build:   ${CPPDUALS_BUILD_FILE}
cppduals-config:  ${CPPDUALS_CONFIG_FILE}
cppduals-clean:
	rm -rf ${CPPDUALS_BASE_DIR}

# Recipies
${CPPDUALS_INSTALL_FILE}: ${CPPDUALS_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${CPPDUALS_BUILD_DIR} && make -j${NJOBS} install
	touch ${CPPDUALS_INSTALL_FILE}

${CPPDUALS_BUILD_FILE}: ${CPPDUALS_CONFIG_FILE}
	cd ${CPPDUALS_BUILD_DIR} && make -j${NJOBS}
	touch ${CPPDUALS_BUILD_FILE}

${CPPDUALS_CONFIG_FILE}: ${CLANG_INSTALL_FILE}
	mkdir -p ${CPPDUALS_BASE_DIR} ${CPPDUALS_BUILD_DIR}
	wget -nc -O ${CPPDUALS_BASE_DIR}/cppduals.tar.gz \
	    https://gitlab.com/tesch1/cppduals/-/archive/v${CPPDUALS_VERSION}/cppduals-v${CPPDUALS_VERSION}.tar.gz \
	    || true
	cd ${CPPDUALS_BASE_DIR} && tar xf cppduals.tar.gz --strip-components 1
	cd ${CPPDUALS_BUILD_DIR} && cmake .. \
	    -DCMAKE_CXX_COMPILER=${CLANGXX} \
	    -DCMAKE_C_COMPILER=${CLANG} \
	    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	    -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	    -DCMAKE_BUILD_TYPE=Release
	touch ${CPPDUALS_CONFIG_FILE}


#-----------------------------------------------------------------------
# Autodiff: (Another) C++ Automatic Differentiation Library
#-----------------------------------------------------------------------

# Key Variables
AUTODIFF_BASE_DIR     := ${BUILD_PREFIX}/autodiff
AUTODIFF_BUILD_DIR    := ${AUTODIFF_BASE_DIR}/build
AUTODIFF_CONFIG_FILE  := ${AUTODIFF_BASE_DIR}/config.done
AUTODIFF_BUILD_FILE   := ${AUTODIFF_BASE_DIR}/build.done
AUTODIFF_INSTALL_FILE := ${AUTODIFF_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: autodiff autodiff-install autodiff-build autodiff-config autodiff-clean
autodiff:         ${AUTODIFF_INSTALL_FILE}
autodiff-install: ${AUTODIFF_INSTALL_FILE}
autodiff-build:   ${AUTODIFF_BUILD_FILE}
autodiff-config:  ${AUTODIFF_CONFIG_FILE}
autodiff-clean:
	rm -rf ${AUTODIFF_BASE_DIR}

# Recipies
${AUTODIFF_INSTALL_FILE}: ${AUTODIFF_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${AUTODIFF_BUILD_DIR} && make -j${NJOBS} install
	touch ${AUTODIFF_INSTALL_FILE}

${AUTODIFF_BUILD_FILE}: ${AUTODIFF_CONFIG_FILE}
	cd ${AUTODIFF_BUILD_DIR} && make -j${NJOBS}
	touch ${AUTODIFF_BUILD_FILE}

${AUTODIFF_CONFIG_FILE}: # ${CLANG_INSTALL_FILE}
	mkdir -p ${AUTODIFF_BASE_DIR} ${AUTODIFF_BUILD_DIR}
	wget -nc -O ${AUTODIFF_BASE_DIR}/autodiff.tar.gz \
	    https://github.com/autodiff/autodiff/archive/v${AUTODIFF_VERSION}.tar.gz \
	    || true
	cd ${AUTODIFF_BASE_DIR} && tar xf autodiff.tar.gz --strip-components 1
	cd ${AUTODIFF_BUILD_DIR} && cmake .. \
	    -DCMAKE_CXX_COMPILER=${CLANGXX} \
	    -DCMAKE_C_COMPILER=${CLANG} \
	    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	    -DCMAKE_PREFIX_PATH=${INSTALL_PREFIX} \
	    -DCMAKE_BUILD_TYPE=Release
	touch ${AUTODIFF_CONFIG_FILE}


#-----------------------------------------------------------------------
# Kokkos: C++ CPU/GPU Abstraction Layer
#-----------------------------------------------------------------------

# Key Variables
KOKKOS_BASE_DIR     := ${BUILD_PREFIX}/kokkos
KOKKOS_BUILD_DIR    := ${KOKKOS_BASE_DIR}/build
KOKKOS_CONFIG_FILE  := ${KOKKOS_BASE_DIR}/config.done
KOKKOS_BUILD_FILE   := ${KOKKOS_BASE_DIR}/build.done
KOKKOS_INSTALL_FILE := ${KOKKOS_BASE_DIR}/install.done

# Shortcut Targets
.PHONY: kokkos kokkos-install kokkos-build kokkos-config kokkos-clean
kokkos:         ${KOKKOS_INSTALL_FILE}
kokkos-install: ${KOKKOS_INSTALL_FILE}
kokkos-build:   ${KOKKOS_BUILD_FILE}
kokkos-config:  ${KOKKOS_CONFIG_FILE}
kokkos-clean:
	rm -rf ${KOKKOS_BASE_DIR}

# Recipies
${KOKKOS_INSTALL_FILE}: ${KOKKOS_BUILD_FILE} | ${INSTALL_PREFIX}
	cd ${KOKKOS_BUILD_DIR} && make -j${NJOBS} install
	touch ${KOKKOS_INSTALL_FILE}

${KOKKOS_BUILD_FILE}: ${KOKKOS_CONFIG_FILE}
	cd ${KOKKOS_BUILD_DIR} && make -j${NJOBS}
	touch ${KOKKOS_BUILD_FILE}

${KOKKOS_CONFIG_FILE}: ${CLANG_INSTALL_FILE} ${CUDA_INSTALL_FILE}
	mkdir -p ${KOKKOS_BASE_DIR} ${KOKKOS_BUILD_DIR}
	wget -nc -O ${KOKKOS_BASE_DIR}/kokkos.tar.gz \
	    https://github.com/kokkos/kokkos/archive/${KOKKOS_VERSION}.tar.gz \
	    || true
	cd ${KOKKOS_BASE_DIR} && tar xf kokkos.tar.gz --strip-components 1
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
	  -DKokkos_CUDA_DIR=${INSTALL_PREFIX}/cuda-${CUDA_VERSION}
	touch ${KOKKOS_CONFIG_FILE}


#-----------------------------------------------------------------------
# Helpers
#-----------------------------------------------------------------------
${INSTALL_PREFIX}:
	mkdir -p $@
