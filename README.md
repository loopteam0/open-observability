# Open Observability Stack

A self-hosted, production-ready observability platform built with open-source tools and wired together via Docker Compose.

## Overview

This stack provides the **three pillars of observability** — metrics, logs, and traces — through a unified pipeline:

```
Your Application
      │
      │  OTLP (gRPC :4317 / HTTP :4318)
      ▼
┌─────────────────────┐
│  OpenTelemetry      │
│  Collector          │
└──────┬──────┬───────┘
       │      │      └──────────────────┐
       │      │                         │
  Metrics   Logs                     Traces
       │      │                         │
       ▼      ▼                         ▼
  Prometheus  Loki                   Jaeger
       │      │                         │
       └──────┴─────────────────────────┘
                        │
                        ▼
                    Grafana
                (port 3000)
```

### Components

| Component | Image | Purpose | Default Port(s) |
|-----------|-------|---------|-----------------|
| **OpenTelemetry Collector** | `otel/opentelemetry-collector-contrib:latest` | Single entry-point for all telemetry; routes to backends | 4317 (gRPC), 4318 (HTTP) |
| **Prometheus** | `prom/prometheus:v2.51.2` | Time-series metrics storage & alerting | 9090 |
| **Loki** | `grafana/loki:2.9.8` | Log aggregation | 3100 |
| **Jaeger** | `jaegertracing/all-in-one:1.57` | Distributed tracing | 16686 (UI) |
| **Grafana** | `grafana/grafana:10.4.2` | Dashboards & visualization | 3000 |

---

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) ≥ 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) v2+

### Run the stack

```bash
# 1. Clone the repository
git clone https://github.com/loopteam0/open-observability.git
cd open-observability

# 2. (Optional) Run the setup helper to ensure all directories exist
chmod +x setup.sh && ./setup.sh

# 3. Start all services in detached mode
docker compose up -d

# 4. Verify that all containers are running
docker compose ps
```

All services will be ready within ~30 seconds. Open Grafana at **http://localhost:3000** (default credentials: `admin` / `admin`).

### Stop the stack

```bash
docker compose down
```

To also remove persistent volumes (metrics and log data):

```bash
docker compose down -v
```

---

## Service Endpoints

| Service | URL | Notes |
|---------|-----|-------|
| Grafana | <http://localhost:3000> | Username: `admin`, Password: `admin` |
| Prometheus | <http://localhost:9090> | Query metrics directly |
| Jaeger UI | <http://localhost:16686> | Browse distributed traces |
| Loki API | <http://localhost:3100> | Log push / query API |
| OTel Collector – OTLP gRPC | `localhost:4317` | Send traces/metrics/logs |
| OTel Collector – OTLP HTTP | `localhost:4318` | Send traces/metrics/logs |
| OTel Collector – Health Check | <http://localhost:13133> | `/` returns 200 when healthy |
| OTel Collector – zPages | <http://localhost:55679> | Internal diagnostics |
| OTel Collector – Prometheus scrape | <http://localhost:8889> | Scraped by Prometheus |

---

## Configuration

All configuration lives in the directories that are bind-mounted into each container.

### OpenTelemetry Collector

File: [`otel-collector/otel-collector-config.yml`](otel-collector/otel-collector-config.yml)

The collector is configured with three pipelines:

| Pipeline | Receiver | Processors | Exporters |
|----------|----------|------------|-----------|
| `traces` | OTLP | memory_limiter → batch | Jaeger (OTLP gRPC), debug |
| `metrics` | OTLP | memory_limiter → batch | Prometheus exporter, debug |
| `logs` | OTLP | memory_limiter → batch | Loki, debug |

### Prometheus

File: [`prometheus/prometheus.yml`](prometheus/prometheus.yml)

Prometheus scrapes the following targets:

| Job | Target | Description |
|-----|--------|-------------|
| `prometheus` | `localhost:9090` | Prometheus self-metrics |
| `otel-collector` | `otel-collector:8889` | Application metrics forwarded via OTel |
| `grafana` | `grafana:3000` | Grafana self-metrics |

To add a new application target, append a `scrape_configs` entry.

### Loki

File: [`loki/loki-config.yml`](loki/loki-config.yml)

Single-instance mode with filesystem storage. Data is persisted to the `loki_data` Docker volume.

### Grafana

Directory: [`grafana/provisioning/`](grafana/provisioning/)

Datasources are provisioned automatically on startup:

- **Prometheus** (default) – `http://prometheus:9090`
- **Loki** – `http://loki:3100`
- **Jaeger** – `http://jaeger:16686`

---

## Sending Telemetry to the Stack

Any application instrumented with the [OpenTelemetry SDK](https://opentelemetry.io/docs/instrumentation/) can send data directly to the collector.

Set these environment variables (or SDK configuration) in your application:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317   # gRPC
# or
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318   # HTTP
OTEL_SERVICE_NAME=my-service
```

---

## Repository Structure

```
open-observability/
├── docker-compose.yml                          # Orchestrates all services
├── setup.sh                                    # Helper to scaffold directories
├── otel-collector/
│   └── otel-collector-config.yml              # Collector pipelines & exporters
├── prometheus/
│   └── prometheus.yml                         # Scrape targets & global config
├── loki/
│   └── loki-config.yml                        # Loki server & storage config
└── grafana/
    └── provisioning/
        └── datasources/
            └── datasources.yml                # Auto-provisioned Grafana datasources
```

---

## CI / Testing

A GitHub Actions workflow (`.github/workflows/ci.yml`) automatically:

1. **Lints** all YAML configuration files with `yamllint`.
2. **Starts** the full Docker Compose stack.
3. **Probes** each service's health endpoint to verify it is running.
4. **Tears down** the stack after tests complete.

The workflow runs on every push and pull request to `main`.

---

## Security Notes

- The default Grafana credentials (`admin`/`admin`) **must** be changed in any non-local environment. Set `GF_SECURITY_ADMIN_PASSWORD` via an environment variable or Docker secret.
- `auth_enabled: false` in `loki-config.yml` is appropriate for a private network but should be enabled with a reverse proxy in a shared environment.

---

## Contributing

1. Fork the repository and create a feature branch.
2. Make your changes and ensure the CI workflow passes.
3. Open a pull request against `main`.
