# Build environment for relocatable tesseract binaries (+ tessdata).
# Native multi-arch: build this image on amd64 or arm64 runners (no QEMU cross).
FROM ubuntu:24.04

ARG TARGETARCH=

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        ninja-build \
        pkg-config \
        autoconf \
        automake \
        libtool \
        patchelf \
        file \
        wget \
        xz-utils \
        zlib1g-dev \
        libpng-dev \
        libjpeg-turbo8-dev \
        libtiff-dev \
        libwebp-dev \
        libgif-dev \
        libopenjp2-7-dev \
        libarchive-dev \
        libcurl4-openssl-dev \
        libicu-dev \
        libpango1.0-dev \
        libcairo2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY scripts/build_and_package.sh /usr/local/bin/build_and_package.sh
RUN chmod +x /usr/local/bin/build_and_package.sh

ENTRYPOINT ["/usr/local/bin/build_and_package.sh"]
