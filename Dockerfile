# # Support setting various labels on the final image
# ARG COMMIT=""
# ARG VERSION=""
# ARG BUILDNUM=""

# # Build Geth in a stock Go builder container
# FROM golang:1.22-alpine as builder

# RUN apk add --no-cache gcc musl-dev linux-headers git

# # Get dependencies - will also be cached if we won't change go.mod/go.sum
# COPY go.mod /go-ethereum/
# COPY go.sum /go-ethereum/
# RUN cd /go-ethereum && go mod download

# ADD . /go-ethereum
# RUN cd /go-ethereum && go run build/ci.go install -static ./cmd/geth

# # Pull Geth into a second stage deploy alpine container
# FROM alpine:latest

# RUN apk add --no-cache ca-certificates
# COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/

# EXPOSE 8545 8546 30303 30303/udp
# ENTRYPOINT ["geth"]

# # Add some metadata labels to help programmatic image consumption
# ARG COMMIT=""
# ARG VERSION=""
# ARG BUILDNUM=""

# LABEL commit="$COMMIT" version="$VERSION" buildnum="$BUILDNUM"

# Support setting various labels on the final image
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

# Stage 1: Build Geth in a stock Go builder container
FROM golang:1.22-alpine AS builder

# Install required dependencies
RUN apk add --no-cache gcc musl-dev linux-headers git

# Set the working directory
WORKDIR /go-ethereum

# Copy and download dependencies (cache these layers for faster builds)
COPY go.mod go.sum ./
RUN go mod download

# Copy the application source code
COPY . .

# Build the Geth binary
RUN go run build/ci.go install -static ./cmd/geth

# Stage 2: Create a minimal deployable image
FROM alpine:latest

# Install CA certificates
RUN apk add --no-cache ca-certificates

# Copy the Geth binary from the builder stage
COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/

# Expose required ports
EXPOSE 8545 8546 30303 30303/udp

# Set the default entrypoint to the Geth binary
ENTRYPOINT ["geth"]

# Add metadata labels for versioning and identification
LABEL commit="$COMMIT" version="$VERSION" buildnum="$BUILDNUM"
