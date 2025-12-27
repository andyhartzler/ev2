# Mautic Self-Hosted

Self-hosted [Mautic](https://mautic.org) marketing automation platform.

## Railway Deployment

### Prerequisites

1. A Railway account
2. A MySQL service already running on Railway

### Deploy to Railway

1. **Create a new service** from this GitHub repo in your Railway project

2. **Add these environment variables** to your Mautic service:

   ```
   # Database connection (use your Railway MySQL values)
   MAUTIC_DB_HOST=mysql.railway.internal
   MAUTIC_DB_PORT=3306
   MAUTIC_DB_DATABASE=railway
   MAUTIC_DB_USER=root
   MAUTIC_DB_PASSWORD=<your-mysql-password>

   # Mautic configuration
   MAUTIC_MESSENGER_DSN_EMAIL=doctrine://default
   MAUTIC_MESSENGER_DSN_HIT=doctrine://default
   ```

3. **Generate a domain** in Railway's service settings

4. **Access your Mautic instance** and complete the installation wizard

### Railway Environment Variables Reference

| Variable | Railway Value |
|----------|---------------|
| `MAUTIC_DB_HOST` | `mysql.railway.internal` (or `MYSQLHOST`) |
| `MAUTIC_DB_PORT` | `3306` (or `MYSQLPORT`) |
| `MAUTIC_DB_DATABASE` | `railway` (or `MYSQLDATABASE`) |
| `MAUTIC_DB_USER` | `root` (or `MYSQLUSER`) |
| `MAUTIC_DB_PASSWORD` | Your MySQL password (or `MYSQLPASSWORD`) |

You can reference Railway's MySQL variables directly:
```
MAUTIC_DB_HOST=${{MySQL.MYSQLHOST}}
MAUTIC_DB_PORT=${{MySQL.MYSQLPORT}}
MAUTIC_DB_DATABASE=${{MySQL.MYSQLDATABASE}}
MAUTIC_DB_USER=${{MySQL.MYSQLUSER}}
MAUTIC_DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
```

---

## Local Development (Docker Compose)

### Requirements

- Docker and Docker Compose
- At least 2GB RAM

### Quick Start

1. **Copy the environment file and configure:**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and set secure passwords.

2. **Start the services:**

   ```bash
   docker compose up -d
   ```

3. **Access Mautic:**

   Open http://localhost:8080 in your browser.

### Services

| Service | Description |
|---------|-------------|
| `db` | MariaDB 11.4 LTS database |
| `mautic_web` | Main Mautic web application |
| `mautic_cron` | Scheduled task processor |
| `mautic_worker` | Background job processor |

### Management Commands

```bash
# View logs
docker compose logs -f

# Stop services
docker compose down

# Update to latest Mautic 6.x
docker compose pull
docker compose up -d
```

---

## Version Info

- **Mautic**: 6.x (latest stable - 6.0.7)
- **PHP**: 8.3 (included in image)
- **Database**: MySQL 8.x / MariaDB 11.x

## Resources

- [Mautic Documentation](https://docs.mautic.org)
- [Official Docker Images](https://hub.docker.com/r/mautic/mautic)
- [Mautic GitHub](https://github.com/mautic/mautic)
