# Dockerfile for Veins Vehicular Network Simulation
FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Set OMNeT++ version
ENV OPP_VERSION=6.0.3

# Install dependencies (needed before java will install)
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends \
    ca-certificates \
    ca-certificates-java \
    ;

# Install dependencies (using the proven script approach)
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends \
    bison \
    build-essential \
    ccache \
    clang-13 \
    curl \
    flex \
    g++ \
    gcc \
    git \
    libxml2-dev \
    lld \
    make \
    openjdk-17-jre \
    perl \
    python3 \
    python3-matplotlib \
    python3-numpy \
    python3-pandas \
    python3-pip \
    python3-scipy \
    tcl-dev \
    tk-dev \
    wget \
    xdg-utils \
    zlib1g-dev \
    # SUMO dependencies
    sumo \
    sumo-tools \
    # X11 for GUI (optional, but useful for debugging)
    xvfb \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure xdg-utils is happy with the system
RUN mkdir -p /usr/share/desktop-directories/

# Install posix_ipc globally
RUN python3 -m pip install posix_ipc

# Get architecture and download OMNeT++
WORKDIR /opt
RUN ARCH=$(uname -m) \
    && mkdir -p omnetpp-${OPP_VERSION} \
    && cd omnetpp-${OPP_VERSION} \
    && curl --location https://github.com/omnetpp/omnetpp/releases/download/omnetpp-${OPP_VERSION}/omnetpp-${OPP_VERSION}-linux-${ARCH}.tgz | tar -xzv --strip-components=1 \
    && cd /opt \
    && ln -sf omnetpp-${OPP_VERSION} omnetpp

# Build OMNeT++
WORKDIR /opt/omnetpp
RUN export PATH=/usr/lib/ccache:$PATH \
    && sed -i 's/WITH_OSG=yes/WITH_OSG=no/g' configure.user \
    && sed -i 's/WITH_QTENV=yes/WITH_QTENV=no/g' configure.user \
    && sed -i 's/WITH_TKENV=yes/WITH_TKENV=no/g' configure.user \
    && export PATH=$PATH:/opt/omnetpp/bin \
    && bash -c "source setenv && CC=clang-13 CXX=clang++-13 ./configure" \
    && bash -c "source setenv && make -j$(nproc) MODE=debug" \
    && bash -c "source setenv && make -j$(nproc) MODE=release" \
    && chmod -R a+wX /opt/omnetpp/

# Set environment variables for OMNeT++
ENV PATH="/opt/omnetpp/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/omnetpp/lib:${LD_LIBRARY_PATH}"

# Create application directory
WORKDIR /app

# Copy Veins source code
COPY . .

# Configure and build Veins
RUN ./configure && make -j$(nproc)

# Record Veins version (if git metadata is available)
RUN /bin/bash -lc 'if git describe --tags --always >/dev/null 2>&1; then \
    TAG=$(git describe --tags --always 2>/dev/null); \
    echo "$TAG" > /app/VEINS_VERSION; \
  elif [ -f doc/version.sh ]; then \
    v=$(bash doc/version.sh); \
    [ -n "$v" ] && echo "veins-$v" > /app/VEINS_VERSION || echo "unknown" > /app/VEINS_VERSION; \
  else \
    echo "unknown" > /app/VEINS_VERSION; \
  fi'

# Create directory for configurations
RUN mkdir -p /app/configs

# Create directory for results
RUN mkdir -p /app/results

# Set the working directory to examples/veins
WORKDIR /app/examples/veins

# Create simple entrypoint script
RUN echo '#!/bin/bash\n\
# Set up environment\n\
export PATH=/opt/omnetpp/bin:$PATH\n\
export LD_LIBRARY_PATH=/opt/omnetpp/lib:$LD_LIBRARY_PATH\n\
\n\
# Print versions\n\
OMNET_VER=$(opp_run -V 2>&1 | head -n1 || true)\n\
if [ -f /app/VEINS_VERSION ]; then VEINS_VER=$(cat /app/VEINS_VERSION); else VEINS_VER="unknown"; fi\n\
echo "OMNeT++: ${OMNET_VER}"\n\
echo "Veins:   ${VEINS_VER}"\n\
\n\
# Execute the simulation\n\
exec ./run "$@"\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Port 9999 will be used to connect to external SUMO service

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command
CMD ["-u", "Cmdenv"]
