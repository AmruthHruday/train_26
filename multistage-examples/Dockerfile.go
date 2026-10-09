############################################################
# EXAMPLE 2: Multi-Stage Dockerfile for Go
############################################################
#
# This is the BEST example to understand multi-stage builds
# because the size difference is MASSIVE:
#
#   Single-stage (golang image):  ~800 MB
#   Multi-stage  (scratch/alpine): ~12 MB   ← 98% smaller!
#
# WHY?
# ----
# Go compiles to a single static binary. The entire Go SDK,
# compiler, standard library, and source code are ONLY needed
# during compilation. At runtime, all you need is the binary.
############################################################


# ========================
# STAGE 1: BUILD STAGE
# ========================
# Full Go SDK image (~800MB) — has compiler, tools, everything
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy source code
COPY main.go .

# Compile the Go application into a static binary
# CGO_ENABLED=0 → no C library dependencies (fully static)
# GOOS=linux    → target Linux OS
RUN CGO_ENABLED=0 GOOS=linux go build -o server main.go

# At this point, /app/server is the compiled binary (~6MB)
# The rest of the ~800MB Go SDK is no longer needed!


# ========================
# STAGE 2: RUNTIME STAGE
# ========================
# "scratch" is a completely EMPTY image (0 bytes!)
# We could also use "alpine" (~5MB) if we need a shell for debugging
FROM alpine:latest

WORKDIR /root/

# Copy ONLY the compiled binary from the build stage
# Everything else (Go SDK, source code, compiler) is discarded
COPY --from=builder /app/server .

# Document the port
EXPOSE 8080

# Run the binary
CMD ["./server"]


############################################################
# COMPARISON — What happens WITHOUT multi-stage:
############################################################
#
# FROM golang:1.22-alpine
# WORKDIR /app
# COPY main.go .
# RUN go build -o server main.go
# EXPOSE 8080
# CMD ["./server"]
#
# This works, but the final image is ~800MB because it still
# contains the entire Go compiler and SDK!
#
# With multi-stage, the final image is just ~12MB.
############################################################
