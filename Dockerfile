# syntax=docker/dockerfile:1.7
FROM debian:bookworm-slim AS linux-base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates file libusb-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY Makefile *.c *.h ./

FROM linux-base AS linux-x64
RUN make clean all \
 && mkdir -p /artifacts/linux-x64 \
 && cp libusb-driver.so libusb-driver-DEBUG.so /artifacts/linux-x64/ \
 && file /artifacts/linux-x64/*.so

FROM linux-base AS linux-x86
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends gcc-multilib libusb-dev:i386 \
 && rm -rf /var/lib/apt/lists/* \
 && make clean lib32 \
 && mkdir -p /artifacts/linux-x86 \
 && cp libusb-driver.so libusb-driver-DEBUG.so /artifacts/linux-x86/ \
 && file /artifacts/linux-x86/*.so

FROM alpine:3.20 AS package
RUN apk add --no-cache bash coreutils findutils unzip zip
WORKDIR /work
COPY --from=linux-x64 /artifacts /artifacts
COPY --from=linux-x86 /artifacts /artifacts
COPY deploy ./deploy
COPY README DEPLOYMENT.md ./
COPY docker/package.sh /usr/local/bin/package-xpcu
RUN chmod 0755 /usr/local/bin/package-xpcu /work/deploy/linux/*.sh /work/deploy/macos/*.sh
ENTRYPOINT ["/usr/local/bin/package-xpcu"]

