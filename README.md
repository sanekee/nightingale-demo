# Nightingale Monitoring Stack Demo

A comprehensive monitoring and observability platform built with **Nightingale**, **Prometheus**, **VictoriaMetrics**, **Grafana**, and supporting services. This stack provides metrics collection, storage, visualization, and alerting capabilities with optional SSO integration via Microsoft Entra ID.

## Architecture Overview

This deployment includes:

- **Nightingale (n9e)** - Core monitoring platform for alerts and rules management
- **Prometheus** - Metrics scraping and collection
- **VictoriaMetrics** - High-performance time-series database backend
- **MySQL** - Database for Nightingale metadata and user management
- **Redis** - Cache and session management
- **Grafana** - Metrics visualization and dashboarding (with optional Entra ID SSO)
- **Categraf** - Lightweight metrics agent for system monitoring
- **LiteLLM** - LLM proxy service for AI integrations
- **Cloudflared** - Secure tunnel to expose services (optional)
- **cAdvisor** - Container monitoring (WSL setup available)

## General Usage

### Prerequisites

- Docker and Docker Compose (version 20.10+)
- Git
- For WSL users: Docker Desktop for Windows with WSL 2 integration

## Manual Password Configuration

⚠️ **Important:** Before starting the stack for the first time, you must manually replace placeholder passwords in configuration files with values from your `.env` file.

### Overview

Two passwords need to be configured:
- **`MYSQL_ROOT_PASSWORD`** - MySQL database root password
- **`NIGHTINGALE_PASSWORD`** - Nightingale admin (root) user password

Both are defined in `.env` and must be manually inserted into configuration files and initialization scripts.

### Configuration Steps

#### 1. MySQL Configuration (`configs/nightingale/config.toml`)

**File:** `configs/nightingale/config.toml`

Find the line:
```toml
DSN="root:${MYSQL_ROOT_PASSWORD}@tcp(mysql:3306)/n9e_v6?charset=utf8mb4&collation=utf8mb4_general_ci&parseTime=True&loc=Local&allowNativePasswords=true"
```

Replace `${MYSQL_ROOT_PASSWORD}` with the actual password value from your `.env` file.

**Example** (if `MYSQL_ROOT_PASSWORD=MySecurePass123`):
```toml
DSN="root:MySecurePass123@tcp(mysql:3306)/n9e_v6?charset=utf8mb4&collation=utf8mb4_general_ci&parseTime=True&loc=Local&allowNativePasswords=true"
```

#### 2. Categraf MySQL Plugin (`configs/categraf/input.mysql/mysql.toml`)

**File:** `configs/categraf/input.mysql/mysql.toml`

Find the line:
```toml
password = "${MYSQL_ROOT_PASSWORD}"
```

Replace `${MYSQL_ROOT_PASSWORD}` with the actual password value from your `.env` file.

**Example** (if `MYSQL_ROOT_PASSWORD=MySecurePass123`):
```toml
password = "MySecurePass123"
```

#### 3. MySQL User Initialization (`configs/mysql/initsql/a-n9e.sql`)

**File:** `configs/mysql/initsql/a-n9e.sql`

Find the line (around line 26):
```sql
insert into `users`(id, username, nickname, password, roles, create_at, create_by, update_at, update_by) values(1, 'root', 'Admin', '${NIGHTINGALE_PASSWORD}', 'Admin', unix_timestamp(now()), 'system', unix_timestamp(now()), 'system');
```

Replace `${NIGHTINGALE_PASSWORD}` with the actual password value from your `.env` file.

**Example** (if `NIGHTINGALE_PASSWORD=MyAdminPass456`):
```sql
insert into `users`(id, username, nickname, password, roles, create_at, create_by, update_at, update_by) values(1, 'root', 'Admin', 'MyAdminPass456', 'Admin', unix_timestamp(now()), 'system', unix_timestamp(now()), 'system');
```

### Verification Checklist

Before running `docker-compose up`, verify:

- [ ] `.env` file exists and contains `MYSQL_ROOT_PASSWORD` and `NIGHTINGALE_PASSWORD`
- [ ] `configs/nightingale/config.toml` has actual password in DSN string (no `${MYSQL_ROOT_PASSWORD}` placeholder)
- [ ] `configs/categraf/input.mysql/mysql.toml` has actual password in password field (no `${MYSQL_ROOT_PASSWORD}` placeholder)
- [ ] `configs/mysql/initsql/a-n9e.sql` has actual password in INSERT statement (no `${NIGHTINGALE_PASSWORD}` placeholder)

---

### Quick Start

1. **Clone the repository:**
   ```bash
   cd compose-bridge
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.sample .env
   ```
   Edit `.env` and set the required values (see [Configuration](#configuration) below).

3. **Start the stack:**
   ```bash
   docker-compose up -d
   ```

4. **Verify services are running:**
   ```bash
   docker-compose ps
   ```

### Service Access

Once deployed, access services at:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Nightingale** | http://localhost:17000 | root / `${NIGHTINGALE_PASSWORD}` |
| **Grafana** | http://localhost:13000 | `${GRAFANA_ADMIN_USER}` / `${GRAFANA_ADMIN_PASSWORD}` |
| **Prometheus** | http://localhost:9090 | — |
| **VictoriaMetrics** | http://localhost:8428 | — |
| **cAdvisor** | http://localhost:13080 | — |
| **MySQL** | localhost:3306 | root / `${MYSQL_ROOT_PASSWORD}` |
| **Redis** | localhost:6379 | — |
| **LiteLLM** | http://localhost:14000 | — |

### Stopping the Stack

```bash
docker-compose down
```

To also remove data:
```bash
docker-compose down -v
```

---

## Running cAdvisor on Windows with WSL

cAdvisor (Google's container monitoring tool) is commented out in the main docker-compose.yaml due to limitations with WSL volume mounting. Use the dedicated cAdvisor compose file on Windows/WSL systems.

### Prerequisites

- Windows 10/11 with WSL 2 enabled
- Docker Desktop for Windows (with WSL 2 integration)
- Access to the `docker-compose-cadvisor.yml` file

### Setup Instructions

1. **Create a dedicated network for cAdvisor** (optional but recommended):
   ```bash
   docker network create monitoring
   ```

2. **Start cAdvisor using the dedicated compose file:**
   ```bash
   docker-compose -f docker-compose-cadvisor.yml up -d
   ```

3. **Verify cAdvisor is running:**
   ```bash
   docker ps | grep cadvisor
   ```

4. **Access cAdvisor dashboard:**
   Open http://localhost:13080 in your browser

### Connecting cAdvisor to Main Stack

To integrate cAdvisor metrics with Nightingale:

1. **Configure Prometheus scrape job** (`configs/prometheus/prometheus.yml`):

   Add or update:
   ```yaml
   scrape_configs:
     - job_name: 'cadvisor'
       static_configs:
         - targets: ['cadvisor:8080']
   ```

   Update the Docker hostname to match your network setup if using a separate network.

2. **Update Nightingale metrics collection** if needed to include cAdvisor targets.

3. **Restart Prometheus:**
   ```bash
   docker-compose restart prometheus
   ```

### WSL-Specific Considerations

- **Volume Mounts:** The main docker-compose.yaml has cAdvisor commented out because WSL doesn't expose `/dev/kmsg` and other necessary kernel interfaces by default. Using the separate compose file avoids these issues.

- **Docker Socket Access:** Ensure Docker Desktop's WSL 2 integration is properly configured and the docker daemon socket is accessible.

- **Localhost vs IP:** Use `localhost:13080` from Windows host, or the Docker gateway IP (typically `172.17.0.1`) from within containers.

### Stopping cAdvisor

```bash
docker-compose -f docker-compose-cadvisor.yml down
```

### Troubleshooting

If cAdvisor fails to start:

1. **Check WSL Docker daemon status:**
   ```bash
   docker ps
   ```

2. **View cAdvisor logs:**
   ```bash
   docker logs cadvisor
   ```

3. **Verify network connectivity:**
   ```bash
   docker network ls
   docker network inspect nightingale
   ```

4. **Check file permissions:** Ensure the docker daemon has access to necessary volume mount points.

---

## Configuration

### Environment Variables (.env)

Create or update `compose-bridge/.env` with required variables:

```env
# MySQL
MYSQL_ROOT_PASSWORD=<your_secure_password>

# Nightingale
NIGHTINGALE_PASSWORD=<your_secure_password>

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<your_secure_password>

# LiteLLM
LITELLM_MASTER_KEY=<your_litellm_key>

# Optional: Cloudflared Tunnel
CLOUDFLARED_TUNNEL_TOKEN=<your_tunnel_token>

# Optional: Microsoft Entra ID (SSO)
ENTRA_ENABLED=false
ENTRA_TENANT_ID=<your_tenant_id>
ENTRA_CLIENT_ID=<your_client_id>
ENTRA_CLIENT_SECRET=<your_client_secret>
ENTRA_ROOT_URL=https://your-grafana-url/

# Optional: Gemini API
GEMINI_API_KEY=<your_gemini_api_key>
```

### Service Configurations

Key configuration files:

- **Nightingale:** `configs/nightingale/config.toml` - Core platform settings
- **Prometheus:** `configs/prometheus/prometheus.yml` - Scrape targets
- **Categraf:** `configs/categraf/config.toml` - Metrics collection
- **VictoriaMetrics:** `configs/victoriametrics/promscrape.yml` - Remote write config
- **LiteLLM:** `configs/litellm/config.yaml` - LLM provider configuration

---

## Monitoring & Observability

### Metrics Collection

- **Categraf** collects system metrics (CPU, memory, disk, network, MySQL, Redis)
- Metrics are sent to Nightingale at `http://nightingale:17000/prometheus/v1/write`
- Prometheus scrapes metrics for alerting rules
- VictoriaMetrics stores time-series data

### Default Dashboards

Grafana dashboards can be imported for:
- Container metrics (cAdvisor)
- MySQL performance
- System resource usage
- Prometheus health

### Alerting

Nightingale manages alert rules. Configure rules via:
- Nightingale web UI at http://localhost:17000
- Alert notification scripts in `configs/nightingale/script/`

---

## Troubleshooting

### Services won't start

1. **Check logs:**
   ```bash
   docker-compose logs -f <service_name>
   ```

2. **Verify port availability:**
   ```bash
   netstat -an | grep 17000  # Nightingale
   netstat -an | grep 13000  # Grafana
   netstat -an | grep 3306   # MySQL
   ```

3. **Ensure passwords are set correctly** in config files (see [Manual Password Configuration](#manual-password-configuration))

### MySQL connection errors

- Verify `MYSQL_ROOT_PASSWORD` is replaced in both `configs/nightingale/config.toml` and `configs/categraf/input.mysql/mysql.toml`
- Check MySQL is fully initialized: `docker-compose logs mysql`

### Nightingale can't log in

- Verify `NIGHTINGALE_PASSWORD` was replaced in `configs/mysql/initsql/a-n9e.sql` before the first startup
- If already started, manually update the database:
  ```bash
  docker-compose exec mysql mysql -uroot -p<PASSWORD> n9e_v6
  UPDATE users SET password='<new_password>' WHERE username='root';
  ```

### cAdvisor not collecting metrics

- Verify it's running: `docker-compose -f docker-compose-cadvisor.yml ps`
- Check Prometheus is configured to scrape cAdvisor
- Review Docker daemon connectivity in WSL

---

## Performance Tuning

### MySQL Optimization

- Adjust `MaxOpenConns` and `MaxIdleConns` in `configs/nightingale/config.toml`
- Monitor performance using Categraf MySQL plugin

### Prometheus Configuration

- Adjust scrape interval: modify `global.scrape_interval` in `configs/prometheus/prometheus.yml`
- Increase storage retention if needed

### VictoriaMetrics

- Monitor disk usage for time-series storage
- Adjust retention policies based on requirements

---

## Security Considerations

⚠️ **Production Deployment Notes:**

1. **Change all default passwords** before deploying to production
2. **Use strong passwords** (minimum 12 characters, mixed case, numbers, symbols)
3. **Enable TLS/HTTPS** for external access (configure via reverse proxy)
4. **Restrict network access** to sensitive services (MySQL, Redis)
5. **Use environment-specific secrets** in production (never commit `.env`)
6. **Enable Entra ID authentication** for Grafana in multi-user environments
7. **Regularly update** Docker images for security patches

---

## Support & Documentation

- **Nightingale Documentation:** https://flashcat.cloud/docs/
- **Prometheus Docs:** https://prometheus.io/docs/
- **Grafana Docs:** https://grafana.com/docs/grafana/latest/
- **VictoriaMetrics Docs:** https://docs.victoriametrics.com/
- **cAdvisor Project:** https://github.com/google/cadvisor

---

## License

See project licensing documentation.
