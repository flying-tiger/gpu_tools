# Overview

This project bootstraps a completely self-contained toolchain
for building and testing GPU-accelerated applications using
C++17 and CUDA. The toolchain is based on the Clang compiler,
as opposed to nVidia's nvcc, due to its superior C++17 support.
The project does not require root privledges and will install
to any user-defined location. Note that by default, this project
assumes the Intel Skylake CPU and nVidia Volta v100 GPU when
builing Kokkos.


# Toolchain Software

| Name      | Purpose                    | Version |
|-----------|----------------------------|---------|
| CMake     | Software build system      | 3.16.2  |
| GCC       | C++17 standard library     | 7.5.0   |
| Clang     | GPU-Capable C++ compiler   | 8.0.1   |
| Cuda      | GPU drivers, runtime, etc. | 9.2     |
| EIGEN     | GPU-capable linear algebra | master  |
| PYBIND    | C++/Python interop         | master  |
| CATCH     | Unit testing framework     | 2.11.1  |
| CPPDUALS  | Automatic differentiation  | 0.4.1   |
| KOKKOS    | GPU abstraction layer      | release-candidate-3.0 |

The following considerations were taken into account when
selecting the versions above:

1. Clang 5+ is the only compiler that supports C++17 on device.
   The nvidia CUDA compiler, nvcc, only support C++14.

2. GCC's libstdc++ 7+ is the first version with mostly-complete
   C++17 library support (std::optional).

3. Prefer using GCC's libstdc++ on linux, vs. using Clang's libc++
   because everything else on the linux platform is built with
   libstdc++.

4. CUDA 9+ is the first version to support the VOLTA architecture.

5. CUDA 9.2+ the first version to support GCC 7. CUDA 10.1 is the
   first to support GCC8.

6. CUDA 9.2 with Clang 8 is a tested configuration. There are no
   configurations tested with CUDA 10.

7. Version 3.0 is the first version of Kokkos with robust CMake
   support.

8. Eigen and Pybind must be at master to compile with Cuda 9.2


# Installation

This project requires a relatively recent Linux environment with an
available C++ compiler (recommend g++ 4.8.5+). Then, simple clone
and enter this repository:

    git clone https://www.github.com/flying-tiger/gpu_tools.git
    cd gpu_tools

Then execute the build and install process as follows:

    make INSTALL_PREFIX=<install_dir> all

This will take several hours to complete as both GCC and Clang must
be built from source. Once completed, the full toolchain will have
been built and installed to the specified path. To use the toolchain,
the following environment variables should be set:

    export PATH="<install_dir>/bin:<install_dir>/cuda-9.2/bin:PATH"
    export LD_LIBRARY_PATH="<install_dir>/lib:<install_dir>/lib64:LD_LIBRARY_PATH"
    export CXX="<install_dir>/bin/clang++"
    export CC="<install_dir>/bin/clang"
    export FC="<install_dir>/bin/gfortran"
    export CUDA_ROOT="<install_dir>/cuda-9.2"
    export CMAKE_PREFIX_PATH="<install_dir>"

A sample modulefile is provided with the project to help properly
configure the users environment.



