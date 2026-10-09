# Multi-Stage Docker Builds — Examples & Explanation 🏗️

This directory contains practical examples of **multi-stage Docker builds**,
showing how they drastically reduce image size and improve security.

---

## What is a Multi-Stage Build?

A **multi-stage build** uses multiple `FROM` statements in a single Dockerfile.
Each `FROM` starts a new "stage". You can selectively copy artifacts from one
stage to another, leaving behind everything you don't need in the final image.

```text
┌──────────────────────────────┐
│  Stage 1: BUILD              │  ← Has compilers, dev tools, source code
│  - Install build tools       │     (large: ~800MB+)
│  - Compile / Build app       │
│  - Generate artifacts        │
└──────────┬───────────────────┘
           │  COPY --from=builder
           ▼
┌──────────────────────────────┐
│  Stage 2: RUNTIME            │  ← Only has the compiled binary / app
│  - Minimal base image        │     (small: ~15-50MB)
│  - Copy artifact from above  │
│  - Run the application       │
└──────────────────────────────┘
```

## Examples Included

| File | Language | Single-Stage Size | Multi-Stage Size | Reduction |
|------|----------|-------------------|------------------|-----------|
| `Dockerfile.python-django` | Python/Django | ~400MB | ~150MB | ~60% |
| `Dockerfile.go` | Go | ~800MB | ~12MB | ~98% |
| `Dockerfile.react` | React/Node.js | ~1.2GB | ~25MB | ~98% |

## How to Try Each Example

```bash
# Build any example (from this directory):
docker build -f Dockerfile.go -t go-multistage-demo .
docker build -f Dockerfile.python-django -t django-multistage-demo .
docker build -f Dockerfile.react -t react-multistage-demo .

# Check the image size:
docker images | grep multistage
```
