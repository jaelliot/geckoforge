# PostgreSQL + pgAdmin (Docker Compose)

This example provides a ready-to-run PostgreSQL 16 development stack with an optional pgAdmin web UI. It is tailored for Phoenix, Python, Go, and any other application that needs a dependable database during development.

⚠️ **SECURITY WARNING**: This example uses default credentials (`dev`/`devpassword`) suitable for local development only. **NEVER use these credentials in production.** For production deployments, use environment variables and secrets management.

**Resource Limits**: The docker-compose.yml includes resource limits (2 CPU cores, 2GB RAM for Postgres) to prevent resource exhaustion. Adjust these based on your system capabilities and workload requirements.

## Quick start

```bash
# Start the stack
docker compose up -d

# Follow logs
docker compose logs -f

# Stop the stack
docker compose down
```

Data lives in Docker volumes (`postgres_data`, `pgadmin_data`) so it persists across restarts. To remove everything, run `docker compose down -v`.

## Connection details

| Component | Value |
|-----------|-------|
| Host | `localhost` |
| PostgreSQL port | `5432` |
| Database | `devdb` |
| Username | `dev` |
| Password | `devpassword` |
| pgAdmin URL | <http://localhost:5050> |
| pgAdmin login | `dev@example.com` / `devpassword` |

### Language snippets

- **Elixir (Ecto):** `ecto://dev:devpassword@localhost:5432/devdb`
- **Phoenix config:**
  ```elixir
  config :my_app, MyApp.Repo,
    username: "dev",
    password: "devpassword",
    hostname: "localhost",
    database: "devdb",
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10
  ```
- **Python (SQLAlchemy):** `postgresql+psycopg://dev:devpassword@localhost:5432/devdb`
- **Go (pgx):** `postgres://dev:devpassword@localhost:5432/devdb`

## Common tasks

- **Backup database:**
  ```bash
  docker compose exec postgres pg_dump -U dev devdb > backup.sql
  ```
- **Restore database:**
  ```bash
  cat backup.sql | docker compose exec -T postgres psql -U dev devdb
  ```
- **Reset stack (drop volumes):**
  ```bash
  docker compose down -v
  docker compose up -d
  ```

## Troubleshooting

- Service unhealthy: run `docker compose ps` and inspect the `STATUS` column. Most start-up issues are missing ports or conflicting processes.
- Port already in use: change the `ports` values in `docker-compose.yml`.
- pgAdmin can't connect: Ensure the PostgreSQL container is healthy and use `docker compose exec postgres pg_isready -U dev`.

## Next steps

- Add more services (Redis, Mailhog) to the same `docker-compose.yml`.
- Commit an `.env` file for secrets in team environments.
- Integrate with Phoenix Mix tasks: `mix ecto.create`, `mix ecto.migrate`, etc.
