FROM docker.io/golang:alpine AS builder

# Install build tools
RUN apk add --no-cache git make gcc musl-dev bash

WORKDIR /src

# Copy everything (submodules already initialized by GitHub Actions)
COPY . .

# Verify submodule contents
RUN ls -la RiV-mesh && \
    cd RiV-mesh && \
    git status && \
    ls -la

# Build environment
ENV CGO_ENABLED=0
ARG GOOS=linux
ARG GOARCH=amd64

# Build with error handling
RUN cd RiV-mesh && \
    [ -f ./build ] || { echo "Error: build script missing!"; exit 1; } && \
    chmod +x ./build && \
    echo "Build script contents:" && \
    head -n 20 ./build && \
    echo "Building..." && \
    GOOS=${GOOS} GOARCH=${GOARCH} ./build || \
    { echo "Build failed with exit code $?"; exit 1; }

FROM docker.io/alpine

RUN apk add --no-cache libgcc

COPY --from=builder /src/RiV-mesh/mesh /usr/bin/mesh
COPY --from=builder /src/RiV-mesh/meshctl /usr/bin/meshctl
COPY --from=builder /src/contrib/docker/entrypoint.sh /usr/bin/entrypoint.sh

RUN chmod +x /usr/bin/entrypoint.sh

VOLUME ["/etc/RiV-chain"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
