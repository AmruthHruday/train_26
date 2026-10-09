# Comprehensive Notes: Everything About Containers & Docker 🐳
> **Source Video:** [Everything about containers and docker | Beginners Guide | multi stage | volumes | networking](https://www.youtube.com/watch?v=3F1ZOkqK7Ww) by **Abhishek Veeramalla** (DevOps Zero to Hero - Day 9)

---

## 📌 Executive Summary
This lecture is a complete, hands-on deep-dive into Docker and Containerization tailored for DevOps engineers. It covers:
1. **Container Fundamentals & OS Virtualization** (VMs vs. Containers, Linux Namespaces & cgroups).
2. **Docker Architecture** (Client-Server Architecture, Docker Daemon, Registries).
3. **Writing Production-Grade Dockerfiles** & Layer Caching.
4. **Multi-Stage Builds** (Drastically reducing image size and enhancing security).
5. **Docker Volumes & Persistence** (Anonymous, Named Volumes, Bind Mounts).
6. **Docker Networking** (Bridge, Host, None, Custom Networks, Container DNS).
7. **Essential Docker CLI Commands Cheatsheet**.

---

## 1. Virtual Machines vs. Containers

| Feature | Virtual Machines (VMs) | Containers (Docker) |
| :--- | :--- | :--- |
| **Virtualization** | Hardware-level (Hypervisor) | OS-level (Shared Host Kernel) |
| **Guest OS** | Full Guest OS in each VM | No Guest OS (Lightweight isolated processes) |
| **Startup Time** | Minutes | Seconds / Milliseconds |
| **Resource Usage** | Heavy (GBs of RAM pre-allocated) | Extremely Lightweight (MBs of RAM) |
| **Isolation Mechanism** | Hypervisor (Type 1 / Type 2) | Linux Kernel Features: **Namespaces** & **cgroups** |

### 🧠 Linux Kernel Primitives Behind Docker:
- **Namespaces (Isolation):** Isolates system resources per container:
  - `pid` namespace (Process isolation)
  - `net` namespace (Network stack isolation)
  - `mnt` namespace (Filesystem mount isolation)
  - `ipc` namespace (Inter-Process Communication)
  - `uts` namespace (Hostname isolation)
- **cgroups / Control Groups (Resource Limits):** Restricts and monitors CPU, Memory, Disk I/O allocated to each container.

---

## 2. Docker Architecture

Docker uses a **Client-Server Architecture**:

```text
  [ Docker Client ] ──────── REST API ────────> [ Docker Host (Daemon: dockerd) ]
   (docker build/run)                           ├── Local Image Cache
                                                ├── Running Containers
                                                └── Docker Engine
                                                         │
                                                  [ Docker Registry ]
                                                  (Docker Hub / ECR)
```

1. **Docker Client (`docker` CLI):** User interface where you run commands like `docker build`, `docker run`.
2. **Docker Daemon (`dockerd`):** Background process on the host managing images, containers, networks, and volumes.
3. **Docker Registry:** Storage repository for Docker images (e.g., Docker Hub, AWS ECR, Quay, GitHub Container Registry).

---

## 3. Dockerfile Best Practices & Layer Caching

A `Dockerfile` is a text document containing commands used to assemble an image.

### Essential Instructions:
- `FROM`: Specifies the base image (e.g., `python:3.11-slim`, `node:20-alpine`, `ubuntu:22.04`).
- `WORKDIR`: Sets the working directory inside the container.
- `COPY`: Copies files/folders from the host into the container.
- `ADD`: Similar to `COPY`, but can auto-extract `.tar.gz` files and download remote URLs (use `COPY` by default).
- `RUN`: Executes build instructions inside the container image during build phase.
- `ENV`: Sets environment variables.
- `EXPOSE`: Documents the network port on which the app listens.
- `CMD` vs `ENTRYPOINT`:
  - `ENTRYPOINT`: Fixed command that always runs. Arguments passed via CLI append to it.
  - `CMD`: Default command or arguments. Can be easily overridden from the command line.

### ⚡ Layer Caching Optimization:
Docker builds images in layers. Put infrequently changing steps (e.g. copying `package.json` or `requirements.txt` and running package installation) **BEFORE** copying application source code.

```dockerfile
# GOOD practice for caching dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

---

## 4. Multi-Stage Builds (Production Optimization)

### Why use Multi-Stage Builds?
In traditional builds, build tools (compilers, SDKs, git, dev dependencies) remain in the final image, resulting in huge images (500MB - 1GB+) and potential security vulnerabilities.

Multi-stage builds allow you to use multiple `FROM` instructions in a single `Dockerfile` and copy only the compiled binaries/artifacts to a minimal runtime image.

### Example: Go Application Multi-Stage Dockerfile

```dockerfile
# Stage 1: Build Environment
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Stage 2: Minimal Production Runtime
FROM alpine:latest
WORKDIR /root/
# Copy binary from builder stage
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

### Benefits:
- **Image Size Reduction:** Shrinks image from ~800MB to ~15MB.
- **Security:** No compiler tools, source code, or build secrets left in production.

---

## 5. Docker Storage & Volumes

Containers have an **ephemeral** writable layer. When a container is removed, data inside that container is lost.

### Storage Mechanisms:
1. **Bind Mounts:**
   - Mounts a specific host path into the container.
   - Syntax: `-v /host/path:/container/path`
   - **Use Case:** Local development (hot reloading code).
2. **Named Volumes (Recommended for Production):**
   - Managed completely by Docker in `/var/lib/docker/volumes/`.
   - Syntax: `-v volume_name:/container/path`
   - Command: `docker volume create my-data`
   - **Use Case:** Database persistence (PostgreSQL, MySQL, MongoDB).
3. **Tmpfs Mounts:** Stored only in host memory (RAM), never written to disk (sensitive data).

---

## 6. Docker Networking

Docker isolates container network interfaces using network namespaces.

### Network Drivers:
1. **Bridge (Default):**
   - Internal virtual network created on a single Docker host.
   - Custom bridge networks allow automatic container DNS name resolution (e.g., `ping backend-container`).
2. **Host:**
   - Shares the host machine's networking stack directly (no port mapping needed).
   - Higher performance, but loses port isolation.
3. **None:**
   - Disables all networking for complete container isolation.
4. **Overlay:**
   - Enables communication between containers running across different physical hosts (used in Docker Swarm & Kubernetes).

### Custom Network Creation & Port Mapping (Django + PostgreSQL Example):
```bash
# 1. Create a custom bridge network
docker network create django-network

# 2. Run PostgreSQL database container on the custom network
docker run -d \
  --name postgres-db \
  --network django-network \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=secret \
  postgres:15-alpine

# 3. Run Django web application container connected to PostgreSQL
docker run -d \
  -p 8000:8000 \
  --name django-app \
  --network django-network \
  -e DATABASE_HOST=postgres-db \
  my-django-app
```

---

## 7. Essential Docker CLI Cheat Sheet

```bash
# Image Management
docker build -t app-name:v1 .       # Build image from Dockerfile
docker images                        # List local images
docker rmi <image_id>                # Delete an image
docker pull <image_name>             # Download image from Docker Hub

# Container Execution
docker run -d -p 8080:80 --name web nginx  # Run container detached (-d) with port mapping (-p)
docker ps                            # List running containers
docker ps -a                         # List all containers (running & stopped)
docker stop <container_id>           # Stop container
docker start <container_id>          # Start stopped container
docker rm <container_id>             # Remove stopped container
docker rm -f <container_id>          # Force remove running container

# Inspection & Debugging
docker logs -f <container_id>        # View live container logs
docker exec -it <container_id> sh    # Open interactive shell in container
docker inspect <container_id>       # View detailed JSON configuration

# Storage & Networking
docker volume ls                     # List Docker volumes
docker volume create <vol_name>      # Create named volume
docker network ls                    # List Docker networks
docker network create <net_name>     # Create custom bridge network
```
