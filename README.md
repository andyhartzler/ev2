# Mautic Self-Hosted

Self-hosted [Mautic](https://mautic.org) marketing automation platform using Docker.

## Requirements

- Docker and Docker Compose
- At least 2GB RAM
- 10GB disk space (recommended)

## Quick Start

1. **Copy the environment file and configure:**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and set secure passwords:
   - `MYSQL_ROOT_PASSWORD` - Database root password
   - `MYSQL_PASSWORD` - Mautic database user password

2. **Start the services:**

   ```bash
   docker compose up -d
   ```

3. **Access Mautic:**

   Open http://localhost:8080 in your browser and complete the installation wizard.

## Services

| Service | Description |
|---------|-------------|
| `db` | MariaDB 11.4 LTS database |
| `mautic_web` | Main Mautic web application |
| `mautic_cron` | Scheduled task processor |
| `mautic_worker` | Background job processor |

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | Database root password | (required) |
| `MYSQL_DATABASE` | Database name | `mautic` |
| `MYSQL_USER` | Database user | `mautic` |
| `MYSQL_PASSWORD` | Database password | (required) |
| `MAUTIC_PORT` | Web interface port | `8080` |
| `DOCKER_MAUTIC_LOAD_TEST_DATA` | Load sample data | `false` |

### Data Persistence

Data is stored in:
- `./mautic/config` - Mautic configuration
- `./mautic/logs` - Application logs
- `./mautic/media` - Uploaded files and images
- Docker volume `mysql-data` - Database files

## Management Commands

```bash
# View logs
docker compose logs -f

# Stop services
docker compose down

# Stop and remove volumes (WARNING: deletes all data)
docker compose down -v

# Update to latest Mautic 6.x
docker compose pull
docker compose up -d

# Access Mautic CLI
docker compose exec mautic_web php bin/console
```

## Production Considerations

For production deployments:

1. **Use a reverse proxy** (nginx/traefik) with SSL/TLS
2. **Set strong passwords** in `.env`
3. **Configure backups** for the database and media volumes
4. **Consider RabbitMQ** for high-volume message queuing (see [official examples](https://github.com/mautic/docker-mautic/tree/main/examples))

## Version Info

- **Mautic**: 6.x (latest stable)
- **MariaDB**: 11.4 LTS
- **PHP**: 8.3 (included in Mautic image)

## Resources

- [Mautic Documentation](https://docs.mautic.org)
- [Official Docker Images](https://hub.docker.com/r/mautic/mautic)
- [Mautic GitHub](https://github.com/mautic/mautic)
