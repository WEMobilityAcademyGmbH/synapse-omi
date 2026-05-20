# syntax=docker/dockerfile:1.7
#
# synapse-omi — Hetzner deploy image (L3-0650).
# Builds only the `backend/` subset of the upstream OMI tree; mobile, firmware,
# desktop and marketplace are excluded (see Re-Use-Map.md → "Ersetzt").
#
# Image diverges from upstream `backend/Dockerfile` in two ways:
#   1. base image: public `python:3.11-slim` instead of
#      `gcr.io/based-hardware-dev/python:3.11-slim-forky` (private registry).
#   2. CMD binds port 8031 — 8030 is occupied by `tenants/claim/8030-taric` in
#      the SYNAPSE service registry.

FROM python:3.11-slim AS builder

ENV PATH="/opt/venv/bin:$PATH" \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

RUN python -m venv /opt/venv

RUN apt-get update && apt-get install -y --no-install-recommends \
        git gcc g++ meson ninja-build python3-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# liblc3 — Opus / LC3 codec used by the WebSocket-audio protocol kept from
# upstream (see Re-Use-Map.md → "Übernommen").
WORKDIR /tmp
RUN git clone --depth=1 https://github.com/google/liblc3.git \
    && cd liblc3 \
    && meson setup build \
    && cd build \
    && meson install \
    && ldconfig \
    && mkdir -p /opt/liblc3 \
    && (cp /usr/local/lib/*/liblc3.so* /opt/liblc3/ 2>/dev/null \
        || cp /usr/local/lib/liblc3.so* /opt/liblc3/) \
    && cd /tmp/liblc3 \
    && python3 -m pip wheel --wheel-dir /tmp/wheels .

WORKDIR /opt/venv
COPY backend/requirements.txt /tmp/requirements.txt
RUN pip install --upgrade -r /tmp/requirements.txt

# ---------------------------------------------------------------------------

FROM python:3.11-slim

WORKDIR /app

ENV PATH="/opt/venv/bin:$PATH" \
    LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH \
    LD_PRELOAD=libjemalloc.so.2 \
    PYTHONUNBUFFERED=1 \
    SYNAPSE_OMI_PORT=8031

RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg curl libjemalloc2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/liblc3/ /usr/local/lib/
COPY --from=builder /tmp/wheels /tmp/wheels
RUN ldconfig \
    && pip install --no-cache-dir /tmp/wheels/*.whl \
    && rm -rf /tmp/wheels

COPY --from=builder /opt/venv /opt/venv

# Only ship the backend tree. Mobile / firmware / desktop / marketplace stay
# in the working tree but are not part of the image.
COPY backend/ /app/

EXPOSE 8031

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${SYNAPSE_OMI_PORT}/health" || exit 1

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${SYNAPSE_OMI_PORT} --loop uvloop"]
