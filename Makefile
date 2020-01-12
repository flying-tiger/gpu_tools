#-----------------------------------------------------------------------
# Toolchain Configuration
#-----------------------------------------------------------------------
INSTALL_PREFIX := /swbuild/tsa/apps/gpu_tools/1.0

GCC_VERSION  := 7.5.0


#-----------------------------------------------------------------------
# GCC Dependency GMP
#-----------------------------------------------------------------------

# Key Variables
GMP_BUILD_DIR    := gmp-${GMP_VERSION}/build
GMP_CONFIG_FILE  := ${GMP_BUILD_DIR}/config.log
GMP_BUILD_FILE   := ${GMP_BUILD_DIR}/tests/test-suite.log
GMP_INSTALL_FILE := ${INSTALL_PREFIX}/lib/libgmp.a

# Shortcut Targets
.PHONY: gmp gmp-install gmp-build gmp-config gmp-clean
gmp:         ${GMP_INSTALL_FILE}
gmp-install: ${GMP_INSTALL_FILE}
gmp-build:   ${GMP_BUILD_FILE}
gmp-config:  ${GMP_CONFIG_FILE}
gmp-clean:
	rm -rf gmp-*

# Recipies
${GMP_INSTALL_FILE}: ${GMP_BUILD_FILE}
	cd ${GMP_BUILD_DIR} && make install

${GMP_BUILD_FILE}: ${GMP_CONFIG_FILE}
	cd ${GMP_BUILD_DIR} && make -j4 && make -j4 check

${GMP_CONFIG_FILE}:
	wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz
	tar xf gmp-${GMP_VERSION}.tar.xz
	mkdir -p ${GMP_BUILD_DIR}
	cd ${GMP_BUILD_DIR} && ../configure --prefix=${INSTALL_PREFIX}


#-----------------------------------------------------------------------
# GCC Dependency MPFR
#-----------------------------------------------------------------------

# Key Variables
MPFR_BUILD_DIR    := mpfr-${MPFR_VERSION}/build
MPFR_CONFIG_FILE  := ${MPFR_BUILD_DIR}/config.log
MPFR_BUILD_FILE   := ${MPFR_BUILD_DIR}/tests/test-suite.log
MPFR_INSTALL_FILE := ${INSTALL_PREFIX}/lib/libmpfr.a

# Shortcut Targets
.PHONY: mpfr mpfr-install mpfr-build mpfr-config mpfr-clean
mpfr:         ${MPFR_INSTALL_FILE}
mpfr-install: ${MPFR_INSTALL_FILE}
mpfr-build:   ${MPFR_BUILD_FILE}
mpfr-config:  ${MPFR_CONFIG_FILE}
mpfr-clean:
	rm -rf mpfr-*

# Recipies
${MPFR_INSTALL_FILE}: ${MPFR_BUILD_FILE}
	cd ${MPFR_BUILD_DIR} && make install

${MPFR_BUILD_FILE}: ${MPFR_CONFIG_FILE}
	cd ${MPFR_BUILD_DIR} && make -j4 && make -j4 check

${MPFR_CONFIG_FILE}: ${GMP_INSTALL_FILE}
	wget https://www.mpfr.org/mpfr-current/mpfr-${MPFR_VERSION}.tar.xz
	tar xf mpfr-${MPFR_VERSION}.tar.xz
	mkdir -p ${MPFR_BUILD_DIR}
	cd ${MPFR_BUILD_DIR} && ../configure --prefix=${INSTALL_PREFIX} \
	                                     --with-gmp=${INSTALL_PREFIX}


#-----------------------------------------------------------------------
# GCC Dependency MPC
#-----------------------------------------------------------------------

# Key Variables
MPC_BUILD_DIR    := mpc-${MPC_VERSION}/build
MPC_CONFIG_FILE  := ${MPC_BUILD_DIR}/config.log
MPC_BUILD_FILE   := ${MPC_BUILD_DIR}/tests/test-suite.log
MPC_INSTALL_FILE := ${INSTALL_PREFIX}/lib/libmpc.a

# Shortcut Targets
.PHONY: mpc mpc-install mpc-build mpc-config mpc-clean
mpc:         ${MPC_INSTALL_FILE}
mpc-install: ${MPC_INSTALL_FILE}
mpc-build:   ${MPC_BUILD_FILE}
mpc-config:  ${MPC_CONFIG_FILE}
mpc-clean:
	rm -rf mpc-*

# Recipies
${MPC_INSTALL_FILE}: ${MPC_BUILD_FILE}
	cd ${MPC_BUILD_DIR} && make install

${MPC_BUILD_FILE}: ${MPC_CONFIG_FILE}
	cd ${MPC_BUILD_DIR} && make -j4 && make -j4 check

${MPC_CONFIG_FILE}: ${MPFR_INSTALL_FILE}
	wget https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz
	tar xf mpc-${MPC_VERSION}.tar.gz
	mkdir -p ${MPC_BUILD_DIR}
	cd ${MPC_BUILD_DIR} && ../configure \
	  --prefix=${INSTALL_PREFIX} \
	  --with-gmp=${INSTALL_PREFIX} \
	  --with-mpfr=${INSTALL_PREFIX}


#-----------------------------------------------------------------------
# GCC Build (Need for libstdc++)
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

${GCC_CONFIG_FILE}: #${MPC_INSTALL_FILE}
	wget -N https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz
	tar xf gcc-${GCC_VERSION}.tar.xz
	cd gcc-${GCC_VERSION} && ./contrib/download_prerequisites
	mkdir -p ${GCC_BUILD_DIR}
	cd ${GCC_BUILD_DIR} && ../configure \
	  --prefix=${INSTALL_PREFIX} \
	  --enable-languages=c,c++,fortran \
	  --disable-multilib



