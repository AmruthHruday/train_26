# ==============================================================================
# 🏗️ STAGE 1: BUILDER STAGE (Multi-Stage Build Pattern)
# ==============================================================================
# Purpose: Compiles dependencies and sets up virtualenv.
# None of the build tools or temporary files will leak into the final image.
FROM python:3.11-slim AS builder

# Prevent Python from writing .pyc files & buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

# 1. Install build tools needed for compiling C-extensions (gcc, make, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. Create an isolated virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 3. Layer Caching: Copy dependencies manifest first
COPY requirements.txt .

# 4. Install dependencies inside the virtualenv
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# ==============================================================================
# 🚀 STAGE 2: PRODUCTION RUNTIME STAGE (Minimal & Secure)
# ==============================================================================
# Starts fresh from a clean slim base image (no compilers, no package managers)
FROM python:3.11-slim AS runtime

# Runtime environment settings
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# 🔒 SECURITY BEST PRACTICE: Non-Root User (Principle of Least Privilege)
# Distroless and hardened security containers never run as root (UID 0)
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --gid 1001 --no-create-home appuser

# 5. Multi-Stage Copy: Copy ONLY the pre-built venv from builder stage
COPY --from=builder /opt/venv /opt/venv

# 6. Copy application source code and set ownership to non-root user
COPY --chown=appuser:appgroup . .

# 💾 STORAGE & PERSISTENCE:
# Prepare directories for SQLite database, media uploads, and static assets
RUN mkdir -p /app/media /app/staticfiles && \
    chown -R appuser:appgroup /app

# Declare Volumes for persistent application data (decoupled from container lifecycle)
VOLUME ["/app/media"]

# Switch execution context to the unprivileged non-root user
USER appuser

# 🌐 NETWORKING:
# Document the port this container listens on (mapped via bridge/host network)
EXPOSE 8000

# 🚦 STARTUP COMMAND:
# Production WSGI server (Gunicorn) with 3 workers
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
