# Complete Docker Mastery Project 🐳🐍

This repository combines **every core Docker topic** into a cohesive, production-grade **Django** application.

---

## 🧭 How Each Topic is Implemented

| Topic | Where It Lives | What It Does |
| :--- | :--- | :--- |
| **Django Framework** | [`myproject/`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/myproject), [`manage.py`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/manage.py) | Full Python Django web app configured with Gunicorn WSGI. |
| **Layer Caching** | [`Dockerfile`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/Dockerfile) (Lines 24–30) | Copies `requirements.txt` and runs `pip install` before copying source code. |
| **Multi-Stage Build** | [`Dockerfile`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/Dockerfile) (Lines 6 & 37) | **Stage 1 (`builder`)** compiles C-dependencies into `/opt/venv`; **Stage 2 (`runtime`)** copies only the virtualenv, dropping build tools. |
| **Distroless / Non-Root Security** | [`Dockerfile`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/Dockerfile) (Lines 46–58) | Follows the security model by creating `appuser` (UID 1001) and dropping root privileges (`USER appuser`). |
| **Volumes (Data Persistence)** | [`Dockerfile`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/Dockerfile) (Line 61) & [`docker-compose.yml`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/docker-compose.yml) | Named volume `postgres_data` persists database records; `media_data` stores uploads. |
| **Bind Mounts (Live Dev)** | [`docker-compose.yml`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/docker-compose.yml) (Line 41) | Mounts `./:/app` so changes to `views.py` update instantly in the container. |
| **Docker Networking** | [`docker-compose.yml`](file:///Users/amruthjagilanka/Downloads/repos/train_26/train_26/docker-compose.yml) (Lines 52–55) | Custom bridge network `django-network` with automatic DNS resolution between `django-app` and `postgres-database`. |

---

## 🏗️ The Master Dockerfile at a Glance

```dockerfile
# STAGE 1: BUILDER (Compiles dependencies inside virtual environment)
FROM python:3.11-slim AS builder
WORKDIR /build
RUN apt-get update && apt-get install -y build-essential
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# STAGE 2: RUNTIME (Lean & unprivileged production container)
FROM python:3.11-slim AS runtime
WORKDIR /app
# Security: Unprivileged non-root user
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --gid 1001 --no-create-home appuser
# Multi-stage copy: Bring only the installed virtualenv
COPY --from=builder /opt/venv /opt/venv
COPY --chown=appuser:appgroup . .
# Volumes for persistent uploads/data
VOLUME ["/app/media"]
USER appuser
EXPOSE 8000
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
```

---

## 🚀 How to Run the Entire Stack

### Option A: Using Docker Compose (Recommended)
This boots up Django, PostgreSQL, the custom bridge network, and named volumes with a single command:

```bash
docker compose up --build
```
Then visit `http://localhost:8000`.

### Option B: Using Pure Docker CLI Commands

```bash
# 1. Create the custom bridge network
docker network create django-network

# 2. Create the named volume for PostgreSQL
docker volume create postgres_data

# 3. Run PostgreSQL container on the network
docker run -d \
  --name postgres-db \
  --network django-network \
  -v postgres_data:/var/lib/postgresql/data \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=secretpassword \
  postgres:15-alpine

# 4. Build the multi-stage Django image
docker build -t my-django-app .

# 5. Run Django with a bind mount (for dev) & port mapping
docker run -d \
  --name django-app \
  --network django-network \
  -p 8000:8000 \
  -v "$(pwd)":/app \
  -e DATABASE_HOST=postgres-db \
  my-django-app
```
